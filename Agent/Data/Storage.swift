import Foundation
import keeta_secure_storage
import KeychainSwift

final class Storage {
    
    private let secureStorage = SecureStorage(keychain: KeychainSwift())
    private let kvStorage = UserDefaults(suiteName: "KeetaAgent")!
    private let prefix: String?
    
    init(prefix: String? = nil) {
        self.prefix = prefix
    }
    
    enum Key: String {
        case agentUser
        case gpgKey
        case sshKey
        case githubUser
    }
    
    var agentUser: AgentUser? {
        get { object(for: .agentUser) }
        set { store(newValue, for: .agentUser) }
    }
    
    var gpgKey: GPGKey? {
        get { object(for: .gpgKey) }
        set { store(newValue, for: .gpgKey) }
    }
    
    var sshKey: SSHKey? {
        get { object(for: .sshKey) }
        set { store(newValue, for: .sshKey) }
    }
    
    var githubUser: GithubUser? {
        get { object(for: .githubUser) }
        set { store(newValue, for: .githubUser) }
    }
    
    // MARK: Helper
    
    private func object<T: Decodable>(for key: Key) -> T? {
        try? secureStorage.object(for: wrap(key))
    }
    
    private func store<T: Encodable>(_ object: T, for key: Key) {
        try? secureStorage.store(object, for: wrap(key))
    }
    
    private func wrap(_ key: Key) -> String {
        if let prefix {
            return "\(prefix)_\(key.rawValue)"
        } else {
            return key.rawValue
        }
    }
}
