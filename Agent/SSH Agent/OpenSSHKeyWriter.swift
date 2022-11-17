import Foundation
import CryptoKit

/// Generates OpenSSH representations of Secrets.
struct OpenSSHKeyWriter {

    /// Generates an OpenSSH data payload identifying the secret.
    /// - Returns: OpenSSH data payload identifying the secret.
    func data<SecretType: Secret>(secret: SecretType) -> Data {
        lengthAndData(of: curveType(for: secret.algorithm, length: secret.keySize).data(using: .utf8)!) +
            lengthAndData(of: curveIdentifier(for: secret.algorithm, length: secret.keySize).data(using: .utf8)!) +
            lengthAndData(of: secret.publicKey)
    }

    /// Generates an OpenSSH string representation of the secret.
    /// - Returns: OpenSSH string representation of the secret.
    func openSSHString<SecretType: Secret>(secret: SecretType, comment: String? = nil) -> String {
        [curveType(for: secret.algorithm, length: secret.keySize), data(secret: secret).base64EncodedString(), comment]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

extension OpenSSHKeyWriter {

    /// Creates an OpenSSH protocol style data object, which has a length header, followed by the data payload.
    /// - Parameter data: The data payload.
    /// - Returns: OpenSSH data.
    func lengthAndData(of data: Data) -> Data {
        let rawLength = UInt32(data.count)
        var endian = rawLength.bigEndian
        return Data(bytes: &endian, count: UInt32.bitWidth/8) + data
    }

    /// The fully qualified OpenSSH identifier for the algorithm.
    /// - Parameters:
    ///   - algorithm: The algorithm to identify.
    ///   - length: The key length of the algorithm.
    /// - Returns: The OpenSSH identifier for the algorithm.
    func curveType(for algorithm: Algorithm, length: Int) -> String {
        switch algorithm {
        case .ellipticCurve:
            return "ecdsa-sha2-nistp" + String(describing: length)
        }
    }

    /// The OpenSSH identifier for an algorithm.
    /// - Parameters:
    ///   - algorithm: The algorithm to identify.
    ///   - length: The key length of the algorithm.
    /// - Returns: The OpenSSH identifier for the algorithm.
    func curveIdentifier(for algorithm: Algorithm, length: Int) -> String {
        switch algorithm {
        case .ellipticCurve:
            return "nistp" + String(describing: length)
        }
    }

}
