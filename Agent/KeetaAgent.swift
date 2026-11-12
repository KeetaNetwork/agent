import Foundation
import OSLog
import SignetKit

#if DEBUG
let agentDirectory = "/.keeta_agent_debug"
let configPath = NSHomeDirectory() + agentDirectory
#else
let agentDirectory = "/.keeta_agent"
let configPath = NSHomeDirectory() + agentDirectory
#endif
/// The socket git, SSH and the GnuPG bridge reach Signet on, served by whichever Signet runs: this
/// app or Workspace for Mac.
let socketPath = SignetPaths.socket()

/// Signet (formerly Keeta Agent): the device's Secure Enclave key, served as an SSH agent, with git
/// signing in SSH's format and, for setups made before, GPG through the bundled GnuPG.
final class KeetaAgent: ObservableObject {
    
    @Published private(set) var gpgKey: GPGKey?
    @Published private(set) var sshKey: SSHKey?
    @Published private(set) var githubUser: GithubUser?
    /// Whether this app serves the socket, or stands by while another Signet (Workspace for Mac) does.
    @Published private(set) var socketState: SignetSocket.State = .stopped
    
    let secureEnclave: SecureEnclaveKeyStore
    let storage: Storage
    let logger = Logger()
    
    private(set) lazy var socket: SignetSocket = {
        let store = secureEnclave
        let agent = SSHAgent(keys: { store.keys() as [any SignetKey] }, processName: { SigningRequestTracer.processName(pid: $0) })
        return SignetSocket(path: socketPath, agent: agent)
    }()
    
    init(secureEnclave: SecureEnclaveKeyStore, storage: Storage) {
        self.secureEnclave = secureEnclave
        self.storage = storage
    }
    
    func setup() async throws {
        try createDirectories()
        
        // Link the bundled GnuPG first: the key check below runs its gpg-connect-agent.
        try await createSymlinks()
        
        await MainActor.run { gpgKey = storage.gpgKey }
        await checkIfGPGKeyExists()
        
        await MainActor.run { sshKey = storage.sshKey }
        
        await MainActor.run { githubUser = storage.githubUser }
        
        serveSocket()
        
        await saveGPGIdentityIfNeeded()
        
        addAsLaunchItem()
    }
    
    /// Releases the socket, so a Signet standing by takes over.
    func stop() {
        socket.stop()
    }
    
    func createNewKey(for name: String, email: String) async -> String? {
        if name.isEmpty {
           return "Please enter a name."
        }
        
        if !isValidEmail(email) {
            return "Please enter a valid email."
        }
        
        do {
            try writeGPGConfigs()
            
            try createUser(with: name, email: email)
            
            guard let key = secureEnclave.keys().first(where: { $0.name == name }) else {
                return "Failed to create ECDSA key pair!"
            }
            
            if let existingGPGKey = gpgKey, existingGPGKey.email == email {
                loadSSHKeyIfNeeded(for: key)
                
                logger.log("GPG creation skipped, key with email '\(email)' already exists.")
                return nil
            }
            
            /// Create GPG key. Git signs in SSH's format on a new setup, so GnuPG doesn't sign commits.
            let gpgKey = try await GPGUtil.createGpgKey(fullName: name, email: email, signCommits: false)
            storage.gpgKey = gpgKey
            DispatchQueue.main.async { self.gpgKey = gpgKey }
            
            /// Create SSH key
            loadSSHKeyIfNeeded(for: key)
            
            /// Git signs through Signet in SSH's format, unless it already signs with another key.
            let outcome = try GitSigning().setUp(
                publicKey: try SSHPublicKey(p256: key.publicKey),
                socket: socketPath,
                folder: SignetPaths.folder(),
                replace: false
            )
            logger.log("Git signing: \(String(describing: outcome))")
            
            await saveGPGIdentityIfNeeded()
            
            return nil
        } catch let error {
            return error.localizedDescription
        }
    }
    
    func didReceive(url: URL) {
        guard let githubToken = url.description.githubToken?.value else { return }
        
        let github = GitHubKeys(token: githubToken)
        let keyTitle = "Signet " + (serialNumber() ?? "Unknown Device")
        
        Task {
            guard let user = try? await github.user() else { return }
            let githubUser = GithubUser(username: user.username, avatarUrl: user.avatarUrl)
            storage.githubUser = githubUser
            
            DispatchQueue.main.async {
                self.githubUser = githubUser
            }
        }
        
        Task {
            if var gpg = gpgKey, !gpg.isUploaded {
                try await github.addGPGKey(armored: gpg.value, title: keyTitle)
                gpg.isUploaded = true
                storage.gpgKey = gpg
                
                DispatchQueue.main.async {
                    self.gpgKey = self.storage.gpgKey
                }
            }
        }
        
        Task {
            /// Keeta Agent added the key for SSH only; GitHub verifies SSH-signed commits against
            /// signing keys, so a key uploaded before goes up again as one.
            if var ssh = sshKey, !ssh.isUploaded || ssh.isSigningKeyUploaded != true {
                try await github.addSSHKey(ssh.value, title: keyTitle)
                ssh.isUploaded = true
                ssh.isSigningKeyUploaded = true
                storage.sshKey = ssh
                
                DispatchQueue.main.async {
                    self.sshKey = self.storage.sshKey
                }
            }
        }
        
        Task {
            if let email = storage.agentUser?.email {
                try await github.addEmail(email)
            }
        }
    }
    
    func logout() {
        githubUser = nil
        storage.githubUser = nil
        sshKey?.isUploaded = false
        sshKey?.isSigningKeyUploaded = false
        gpgKey?.isUploaded = false
        storage.gpgKey = gpgKey
        storage.sshKey = sshKey
    }
    
    // MARK: Helper
    
    /// Serves Signet's socket, or stands by while Workspace for Mac serves it and takes over when it
    /// quits; Keeta Agent's old socket path, and `$SSH_AUTH_SOCK` as Keeta Agent set it up, lead to it.
    private func serveSocket() {
        socket.onChange = { [weak self] state in
            DispatchQueue.main.async { self?.socketState = state }
        }
        do {
            try socket.start()
        } catch {
            logger.log("Couldn't serve the socket. Error: \(error.localizedDescription)")
        }
        socket.watch(every: 2)
        do {
            try socket.link(from: SignetPaths.keetaAgentSocket())
        } catch {
            logger.log("Couldn't link Keeta Agent's socket path. Error: \(error.localizedDescription)")
        }
        Task {
            do {
                try await CommandExecutor.execute(.configureSocket(socketPath: socketPath))
            } catch {
                logger.log("Couldn't link SSH_AUTH_SOCK. Error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Keeps the GPG identity's public half in Signet's folder, for the OpenPGP signer that will
    /// replace GnuPG and must go on signing as the same identity.
    private func saveGPGIdentityIfNeeded() async {
        guard let gpgKey, (try? GPGIdentity.load(from: SignetPaths.folder())) == nil else { return }
        do {
            let listing = try await CommandExecutor.execute(.listGPGKeysWithColons).value
            let identity = try GPGIdentity(listing: listing, keyID: gpgKey.id, armoredPublicKey: gpgKey.value)
            try identity.save(in: SignetPaths.folder())
        } catch {
            logger.log("Couldn't save the GPG identity. Error: \(error.localizedDescription)")
        }
    }
    
    private func createDirectories() throws {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: configPath) {
            try fileManager.createDirectory(
                at: .init(fileURLWithPath: configPath),
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 448]
            )
        }
    }
    
    private func createSymlinks() async throws {
        do {
            try await GPGUtil.createSymlinks()
        } catch let error {
            logger.log("Couldn't create symlinks. Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func writeGPGConfigs() throws {
        do {
            try GPGUtil.writeConfigs()
        } catch let error {
            logger.log("Couldn't write GPG configs. Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func addAsLaunchItem() {
        #if DEBUG
        return
        #endif
        
        if !LaunchAtLogin.isEnabled {
            LaunchAtLogin.isEnabled = true
        }
    }
    
    private func createUser(with name: String, email: String, createKeyPair: Bool = true) throws {
        let newUser = AgentUser(fullName: name, email: email)
        
        if storage.agentUser != newUser {
            storage.agentUser = newUser
        }
        
        if createKeyPair, !secureEnclave.keys().contains(where: { $0.name == name }) {
            /// Create ECDSA key pair
            _ = try secureEnclave.makeKey(named: name)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func checkIfGPGKeyExists() async {
        // Attempt to restore GPG key
        if gpgKey == nil,
           let restoredKey = try? await GPGUtil.restoreLocalGpgKey(in: agentDirectory) {
            storage.gpgKey = restoredKey
            try! createUser(with: restoredKey.fullName, email: restoredKey.email, createKeyPair: false)
            await MainActor.run { gpgKey = restoredKey }
            return
        }
        
        if let keyId = gpgKey?.id {
            do {
                if try await GPGUtil.keyExists(for: keyId) == false {
                    storage.gpgKey = nil
                    storage.githubUser = nil
                    
                    // @Published values consumed by the UI
                    DispatchQueue.main.async {
                        self.gpgKey = nil
                        self.githubUser = nil
                    }
                }
            } catch {}
        }
    }
    
    private func loadSSHKeyIfNeeded(for key: SecureEnclaveKey) {
        if sshKey == nil, let line = try? SSHPublicKey(p256: key.publicKey).line {
            let sshKey = SSHKey(value: line, isUploaded: false)
            storage.sshKey = sshKey
            DispatchQueue.main.async { self.sshKey = sshKey }
        }
    }
}
