import Foundation
import OSLog

#if DEBUG
let agentDirectory = "/.keeta_agent_debug"
let configPath = NSHomeDirectory() + agentDirectory
#else
let agentDirectory = "/.keeta_agent"
let configPath = NSHomeDirectory() + agentDirectory
#endif
let homeDirectory = NSHomeDirectory() + "/Library/KeetaAgent/Data"
let socketPath = (homeDirectory as NSString).appendingPathComponent("socket.ssh")

final class KeetaAgent: ObservableObject {
    
    @Published private(set) var gpgKey: GPGKey?
    @Published private(set) var sshKey: SSHKey?
    @Published private(set) var githubUser: GithubUser?
    
    let secureEnlave: SecureEnclaveStore
    let storage: Storage
    let sshWriter = OpenSSHKeyWriter()
    let logger = Logger()
    
    private(set) lazy var agent: SSHAgent = SSHAgent(store: secureEnlave)
    private(set) lazy var socket: SocketController = SocketController(path: socketPath)
    
    init(secureEnlave: SecureEnclaveStore, storage: Storage) {
        self.secureEnlave = secureEnlave
        self.storage = storage
    }
    
    func setup() async throws {
        try createDirectories()
        
        await MainActor.run { gpgKey = storage.gpgKey }
        await checkIfGPGKeyExists()
        
        await MainActor.run { sshKey = storage.sshKey }
        // TODO: check if the ssh key exists locally
        
        await MainActor.run { githubUser = storage.githubUser }
        
        secureEnlave.setup()
        
        try await symlinkSocketPath()
        
        try await createSymlinks()
        
        socket.handler = agent.handle(reader:writer:)
        
        addAsLaunchItem()
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
            
            guard let secret = secureEnlave.secrets.first(where: { $0.name == name }) else {
                return "Failed to create ECDSA key pair!"
            }
            
            if let existingGPGKey = gpgKey, existingGPGKey.email == email {
                createSSHKeyIfNeeded(for: secret)
                
                logger.log("GPG creatiom skipped, key with email '\(email)' already exists.")
                return nil
            }
            
            /// Create GPG key
            let gpgKey = try await GPGUtil.createGpgKey(fullName: name, email: email)
            storage.gpgKey = gpgKey
            DispatchQueue.main.async { self.gpgKey = gpgKey }
            
            /// Create SSH key
            createSSHKeyIfNeeded(for: secret)
            
            return nil
        } catch let error {
            return error.localizedDescription
        }
    }
    
    func didReceive(url: URL) {
        guard let githubToken = url.description.githubToken?.value else { return }
        
        let githubApi = GithubAPI(token: githubToken)
        
        Task {
            let user = await githubApi.pullUser()
            storage.githubUser = user
            
            DispatchQueue.main.async {
                self.githubUser = user
            }
        }
        
        Task {
            if var gpg = gpgKey, !gpg.isUploaded {
                try await githubApi.uploadGPG(key: gpg.value)
                gpg.isUploaded = true
                storage.gpgKey = gpg
                
                DispatchQueue.main.async {
                    self.gpgKey = self.storage.gpgKey
                }
            }
        }
        
        Task {
            if var ssh = sshKey, !ssh.isUploaded {
                try await githubApi.uploadSSH(key: ssh.value)
                ssh.isUploaded = true
                storage.sshKey = ssh
                
                DispatchQueue.main.async {
                    self.sshKey = self.storage.sshKey
                }
            }
        }
        
        Task {
            if let email = storage.agentUser?.email {
                try await githubApi.uploadEmail(email)
            }
        }
    }
    
    func logout() {
        githubUser = nil
        storage.githubUser = nil
        sshKey?.isUploaded = false
        gpgKey?.isUploaded = false
        storage.gpgKey = gpgKey
        storage.sshKey = sshKey
    }
    
    // MARK: Helper
    
    private func createDirectories() throws {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: homeDirectory) {
            try fileManager.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
        }
        
        if !fileManager.fileExists(atPath: configPath) {
            try fileManager.createDirectory(
                at: .init(fileURLWithPath: configPath),
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 448]
            )
        }
    }
    
    private func symlinkSocketPath() async throws {
        do {
            try await CommandExecutor.execute(.configureSocket(socketPath: socketPath))
        } catch let error {
            logger.log("Couldn't create symlink socket path. Error: \(error.localizedDescription)")
            throw error
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
        
        if createKeyPair {
            /// Create ECDSA key pair
            try secureEnlave.createKeyPairIfNeeded(with: name)
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
            storage.githubUser = nil
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
    
    private func createSSHKeyIfNeeded(for secret: Secret) {
        if sshKey == nil {
            let sshKeyValue = OpenSSHKeyWriter().openSSHString(secret: secret)
            let sshKey = SSHKey(value: sshKeyValue, isUploaded: false)
            storage.sshKey = sshKey
            DispatchQueue.main.async { self.sshKey = sshKey }
        }
    }
}
