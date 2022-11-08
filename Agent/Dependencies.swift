import Foundation

class Dependencies {
    static let all = Dependencies()
    
    private(set) lazy var store = SecureEnclaveStore()
    private(set) lazy var publicKeyFileStoreController = PublicKeyFileStoreController(homeDirectory: homeDirectory)
    private(set) lazy var agent: SSHAgent = SSHAgent(store: store)
    private(set) lazy var socket: SocketController = {
        let path = (homeDirectory as NSString).appendingPathComponent("socket.ssh") as String
        return SocketController(path: path)
    }()
    
    static func setup() {
        createHomeDirectory()
        
        DispatchQueue.main.async {
            Self.all.socket.handler = Self.all.agent.handle(reader:writer:)
        }
        
        try! Self.all.store.create(name: "Roy 2")
    }
    
    // MARK: Helper
    
    private static func createHomeDirectory() {
        if !FileManager.default.fileExists(atPath: homeDirectory) {
            try! FileManager.default.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
        }
    }
}
