import Foundation

class Dependencies {
    static let all = Dependencies()
    
    private(set) lazy var keetaAgent = KeetaAgent(secureEnlave: secureEnlave, storage: storage)
    private(set) lazy var secureEnlave = SecureEnclaveStore()
    private(set) lazy var storage = Storage()
    
    func setup() {
        Task {
            try await keetaAgent.setup()
        }
    }
}
