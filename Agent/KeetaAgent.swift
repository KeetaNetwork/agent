import Foundation
import OSLog

let socketPath = (homeDirectory as NSString).appendingPathComponent("socket.ssh")
let homeDirectory = NSHomeDirectory() + "/Library/KeetaAgent/Data"

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
        
        createHomeDirectory()
        
        gpgKey = storage.gpgKey
        // temporary migration
        if gpgKey == nil {
            reset()
        }
        
        sshKey = storage.sshKey
        githubUser = storage.githubUser
        
        secureEnlave.setup()
        
        socket.handler = agent.handle(reader:writer:)
        
        writeConfigs()
        
        checkIfKeyStillExists()
    }
    
    func createNewKey(for name: String, email: String) async -> String? {
        if name.isEmpty {
           return "Please enter a name."
        }
        
        if !isValidEmail(email) {
            return "Please enter a valid email."
        }
        
        #if !DEBUG
        guard isInApplicationsDirectory else {
            return "Make sure 'Keeta Agent' is located in your Applications directory."
        }
        writeConfigs()
        #endif
        
        do {
            /// Create ECDSA key pair
            try secureEnlave.createKeyPairIfNeeded(with: name)
            
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
        
        if !storage.didUploadGPGKey, let gpg = gpgKey {
            Task {
                try await githubApi.uploadGPG(key: gpg.value)
                storage.didUploadGPGKey = true
            }
        }
        
        if !storage.didUploadSSHKey, let ssh = sshKey {
            Task {
                try await githubApi.uploadSSH(key: ssh.value)
            }
        }
    }
    
    // MARK: Helper
    
    private var isInApplicationsDirectory: Bool {
        let locations = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask)
        let applicationsPath = locations.first!.path
        return gpgPath.hasPrefix(applicationsPath)
    }
    
    private func createHomeDirectory() {
        if !FileManager.default.fileExists(atPath: homeDirectory) {
            try! FileManager.default.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
        }
    }
    
    private func writeConfigs() {
        #if !DEBUG
        guard isInApplicationsDirectory else { return }
        #endif
        
         do {
            try GPGUtil.writeConfigs()
        } catch let error {
            logger.log("Couldn't write GPG configs. Error: \(error.localizedDescription)")
        }
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
        storage.didUploadGPGKey = false
        storage.didUploadSSHKey = false
    }
    
    private func createSSHKeyIfNeeded(for secret: Secret) {
        if sshKey == nil {
            let sshKeyValue = OpenSSHKeyWriter().openSSHString(secret: secret)
            let sshKey = SSHKey(value: sshKeyValue)
            storage.sshKey = sshKey
            DispatchQueue.main.async { self.sshKey = sshKey }
        }
    }
}
