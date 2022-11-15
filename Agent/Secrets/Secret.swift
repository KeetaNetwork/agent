import Foundation

protocol Secret {
    typealias ID = String
    
    var id: ID { get }
    var name: String { get }
    var algorithm: Algorithm { get }
    var keySize: Int { get }
    var publicKey: Data { get }
}

struct SecureEnclaveSecret: Secret {
    let id: String
    let name: String
    let algorithm = Algorithm.ellipticCurve
    let keySize = 256
    let publicKey: Data
}
