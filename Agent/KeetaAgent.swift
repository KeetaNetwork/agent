import Foundation
import OSLog

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
        
        gpgKey = storage.gpgKey
        // temporary migration
        if gpgKey == nil {
            storage.githubUser = nil
        }
        
        sshKey = storage.sshKey
        githubUser = storage.githubUser
        
        secureEnlave.setup()
        
        socket.handler = agent.handle(reader:writer:)
        
        do {
            try GPGUtil.writeConfigs()
        } catch let error {
            logger.log("Couldn't write GPG configs. Error: \(error.localizedDescription)")
        }
        
        checkIfKeyStillExists()
    }
    
    func createNewKey(for name: String, email: String) async -> String? {
        if name.isEmpty {
           return "Please enter a name."
        }
        
        if !isValidEmail(email) {
            return "Please enter a valid email."
        }
        
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
                // reset
                DispatchQueue.main.async {
                    self.storage.gpgKey = nil
                    self.gpgKey = nil
                    self.storage.githubUser = nil
                    self.githubUser = nil
                }
            }
        }
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
