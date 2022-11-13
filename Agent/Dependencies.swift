import Foundation

let homeDirectory = NSHomeDirectory() + "/Library/KeetaAgent/Data"
let socketPath = (homeDirectory as NSString).appendingPathComponent("socket.ssh")

class Dependencies {
    static let all = Dependencies()
    
    private(set) lazy var gpgService = GPGService()
    private(set) lazy var store = SecureEnclaveStore()
    private(set) lazy var publicKeyFileStoreController = PublicKeyFileStoreController(homeDirectory: homeDirectory)
    private(set) lazy var agent: SSHAgent = SSHAgent(store: store)
    private(set) lazy var socket: SocketController = SocketController(path: socketPath)
    
    func setup() {
        createHomeDirectory()
        
//        gpgService.setupConfigs()
        
        store.setup()
        
        socket.handler = agent.handle(reader:writer:)
    }
    
    // MARK: Helper
    
    private func createHomeDirectory() {
        if !FileManager.default.fileExists(atPath: homeDirectory) {
            try! FileManager.default.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
        }
    }
}
