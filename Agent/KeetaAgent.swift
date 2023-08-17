import Foundation
import OSLog

#if DEBUG
let configPath = NSHomeDirectory() + "/.keeta_agent_debug"
#else
let configPath = NSHomeDirectory() + "/.keeta_agent"
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
    
    func setup() {
        print(gpgPath)
        
        createDirectories()
        
        gpgKey = storage.gpgKey
        // temporary migration
        if gpgKey == nil {
            reset()
        } else {
            writeConfigs()
            
            storage.agentUser = .init(fullName: gpgKey!.fullName, email: gpgKey!.email)
            
            Task {
                try await CommandExecutor.execute(.gitSetGPGProgram(path: gpgPath))
            }
        }
        
        sshKey = storage.sshKey
        githubUser = storage.githubUser
        
        secureEnlave.setup()
        
        socket.handler = agent.handle(reader:writer:)
        
        symlinkSocketPath()
        
        createSymlinks()
        
        checkIfKeyStillExists()
        
        addAsLaunchItem()
    }
    
    func createNewKey(for name: String, email: String) async -> String? {
        if name.isEmpty {
           return "Please enter a name."
        }
        
        if !isValidEmail(email) {
            return "Please enter a valid email."
        }
        
        writeConfigs()
        
        do {
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
    
    private func createDirectories() {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: homeDirectory) {
            try! fileManager.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
        }
        
        if !fileManager.fileExists(atPath: configPath) {
            try! fileManager.createDirectory(
                at: .init(fileURLWithPath: configPath),
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 448]
            )
        }
    }
    
    private func symlinkSocketPath() {
        Task {
            try await CommandExecutor.execute(.configureSocket(socketPath: socketPath))
        }
    }
    
    private func createSymlinks() {
        Task {
            do {
                try await GPGUtil.createSymlinks()
            } catch let error {
                logger.log("Couldn't create symlinks. Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func writeConfigs() {
        do {
            try GPGUtil.writeConfigs()
        } catch let error {
            logger.log("Couldn't write GPG configs. Error: \(error.localizedDescription)")
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
    
    private func createUser(with name: String, email: String) throws {
        let newUser = AgentUser(fullName: name, email: email)
        
        if storage.agentUser != newUser {
            storage.agentUser = newUser
        }
        
        /// Create ECDSA key pair
        try secureEnlave.createKeyPairIfNeeded(with: name)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func checkIfKeyStillExists() {
        guard let keyId = gpgKey?.id else { return }
        
        Task {
            if await GPGUtil.keyExists(for: keyId) == false {
                DispatchQueue.main.async {
                    self.reset()
                }
            }
        }
    }
    
    private func reset() {
        storage.gpgKey = nil
        gpgKey = nil
        
        githubUser = nil
        storage.githubUser = nil
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
