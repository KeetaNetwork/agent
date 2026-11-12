import Foundation

struct SSHKey: Codable {
    let value: String
    var isUploaded: Bool
    /// Whether GitHub has it as a signing key too (Signet 2.0); nil for a key Keeta Agent uploaded.
    var isSigningKeyUploaded: Bool? = nil
}
