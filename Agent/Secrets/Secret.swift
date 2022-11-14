import Foundation

protocol Secret {
    typealias ID = String
    
    var id: ID { get }
    /// A user-facing string identifying the Secret.
    var name: String { get }
    /// The algorithm this secret uses.
    var algorithm: Algorithm { get }
    /// The key size for the secret.
    var keySize: Int { get }
    /// Whether the secret requires authentication before use.
    var requiresAuthentication: Bool { get }
    /// The public key data for the secret.
    var publicKey: Data { get }
}

struct SecureEnclaveSecret: Secret {
    let id: String
    let name: String
    let algorithm = Algorithm.ellipticCurve
    let keySize = 256
    let requiresAuthentication: Bool
    let publicKey: Data
}
