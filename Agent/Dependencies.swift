import Foundation

class Dependencies {
    static let all = Dependencies()
    
    private(set) lazy var keetaAgent = KeetaAgent(secureEnlave: secureEnlave, storage: storage)
    private(set) lazy var secureEnlave = SecureEnclaveStore()
    private(set) lazy var storage = Storage(prefix: serialNumber())
    // TODO: remove with next major version bump
    private lazy var legacyStorage = Storage()

    func setup() {
        Task {
            migrate(from: legacyStorage, to: storage)
            
            try await keetaAgent.setup()
        }
    }
    
    func migrate(from legacyStorage: Storage, to newStorage: Storage) {
        if let agentUser = legacyStorage.agentUser, newStorage.agentUser == nil {
            newStorage.agentUser = agentUser
        }
        if let gpgKey = legacyStorage.gpgKey, newStorage.gpgKey == nil {
            newStorage.gpgKey = gpgKey
        }
        if let sshKey = legacyStorage.sshKey, newStorage.sshKey == nil {
            newStorage.sshKey = sshKey
        }
        if let githubUser = legacyStorage.githubUser, newStorage.githubUser == nil {
            newStorage.githubUser = githubUser
        }
    }
}
