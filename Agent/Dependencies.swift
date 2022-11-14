import Foundation

let homeDirectory = NSHomeDirectory() + "/Library/KeetaAgent/Data"
let socketPath = (homeDirectory as NSString).appendingPathComponent("socket.ssh")

class Dependencies {
    static let all = Dependencies()
    
    private(set) lazy var keetaAgent = KeetaAgent(secureEnlave: secureEnlave, gpgService: gpgService, storage: storage)
    private(set) lazy var gpgService = GPGService(store: storage)
    private(set) lazy var secureEnlave = SecureEnclaveStore()
    private(set) lazy var storage = Storage()
    
    func setup() {
        createHomeDirectory()
        
        secureEnlave.setup()
        
        gpgService.setup()
        
        keetaAgent.setup()
    }
    
    // MARK: Helper
    
    private func createHomeDirectory() {
        if !FileManager.default.fileExists(atPath: homeDirectory) {
            try! FileManager.default.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
        }
    }
}
