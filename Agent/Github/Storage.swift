import Foundation
import keeta_secure_storage
import KeychainSwift

final class Storage: GPGStore {
    
//    @Published private(set) var user: AgentUser?
    
    private let secureStorage = SecureStorage(keychain: KeychainSwift())
    private let kvStorage = UserDefaults(suiteName: "KeetaAgent")!
    
    enum Key: String {
        case gpgConfigSetup
        case gpgKeyUploaded
        case gpgKey
        case sshKey
        case sshKeyUploaded
        case githubUser
    }
    
    var didUploadSSHKey: Bool {
        get { kvStorage.bool(forKey: Key.sshKeyUploaded.rawValue) }
        set { kvStorage.set(newValue, forKey: Key.sshKeyUploaded.rawValue) }
    }
    
    var didUploadGPGKey: Bool {
        get { kvStorage.bool(forKey: Key.gpgKeyUploaded.rawValue) }
        set { kvStorage.set(newValue, forKey: Key.gpgKeyUploaded.rawValue) }
    }
    
    var didWriteGPGConfigs: Bool {
        get { kvStorage.bool(forKey: Key.gpgConfigSetup.rawValue) }
        set { kvStorage.set(newValue, forKey: Key.gpgConfigSetup.rawValue) }
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
        try? secureStorage.object(for: key.rawValue)
    }
    
    private func store<T: Encodable>(_ object: T, for key: Key) {
        try? secureStorage.store(object, for: key.rawValue)
    }
    
//    init() {
//        // attempt to load user details from storage
//        user = try? storage.object(for: agentUserKey)
//    }
//
////    func storeGithubUser(user: GithubUser, token: String) {
////        guard let currentUser = self.user else { return }
////        AgentUser(githubUser: <#T##GithubUser#>, gpgKey: <#T##GPGKey#>, sshKey: <#T##SSHKey#>)
////
////        let updatedUser = AgentUser(token: token, github: user, gpgKey: currentUser.gpgKey, sshKey: currentUser.sshKey)
////        storeUser(user: updatedUser)
////    }
//
//    func generateKeys(name: String, email: String, for user: GithubUser) {
//        let TEMP_KEY = "TEST KEY ONLY"
//        let gpgKey = GPGKey(key: TEMP_KEY, fullName: name, email: email)
//        let sshKey = SSHKey(key: TEMP_KEY)
//        let agentUser = AgentUser(githubUser: user, gpgKey: gpgKey, sshKey: sshKey)
//
////        Task {
////            try await GithubAPI.uploadGPG(key: gpgKey)
////            try await GithubAPI.uploadSSH(key: sshKey)
////        }
//
//        storeUser(user: agentUser)
//    }
//
//    // MARK: Helper
//
//    private func storeUser(user: AgentUser) {
//        try? self.storage.store(user, for: agentUserKey)
//        guard let user: AgentUser = try? storage.object(for: agentUserKey) else { return }
//
//        DispatchQueue.main.async {
//            self.user = user
//        }
//    }
}
