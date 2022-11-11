import Foundation

class Dependencies {
    static let all = Dependencies()
    
    private(set) lazy var store = SecureEnclaveStore()
    private(set) lazy var publicKeyFileStoreController = PublicKeyFileStoreController(homeDirectory: homeDirectory)
    private(set) lazy var agent: SSHAgent = SSHAgent(store: store)
    private(set) lazy var socket: SocketController = SocketController(path: socketPath)
    
    static func setup() {
        createHomeDirectory()
        
        DispatchQueue.main.async {
            Self.all.socket.handler = Self.all.agent.handle(reader:writer:)
        }
        
//        try! Self.all.store.create(name: "Roy 2")
        
        Task {
            try await createGpgKey(fullName:email:)
        }
    }
    
    // MARK: Helper
    
    private static func createHomeDirectory() {
        if !FileManager.default.fileExists(atPath: homeDirectory) {
            try! FileManager.default.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
        }
    }
}
