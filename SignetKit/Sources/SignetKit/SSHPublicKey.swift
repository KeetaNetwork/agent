import Crypto
import Foundation

/// A P-256 public key as SSH names it: `ecdsa-sha2-nistp256`.
public struct SSHPublicKey: Sendable, Hashable {
  static let algorithm = "ecdsa-sha2-nistp256"
  static let curve = "nistp256"

  /// X9.63 uncompressed bytes.
  public let x963: Data

  public init(p256 x963: Data) throws {
    guard (try? P256.Signing.PublicKey(x963Representation: x963)) != nil else { throw SignetError.notP256 }
    self.x963 = x963
  }

  /// The key blob, as SSH's agent protocol and signatures carry it.
  public var blob: Data {
    SSHWire.string(Self.algorithm) + SSHWire.string(Self.curve) + SSHWire.string(x963)
  }

  /// The line an `authorized_keys` or `.pub` file holds, without a comment:
  /// `ecdsa-sha2-nistp256 AAAA…`.
  public var line: String { "\(Self.algorithm) \(blob.base64EncodedString())" }

  /// The fingerprint `ssh-keygen -l` shows: `SHA256:` and unpadded base64.
  public var fingerprint: String {
    let b64 = Data(SHA256.hash(data: blob)).base64EncodedString()
    return "SHA256:" + b64.trimmingCharacters(in: CharacterSet(charactersIn: "="))
  }

  /// The key a `.pub` line names, ignoring its comment; nil for anything else.
  public init?(line: String) {
    let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
    guard parts.count >= 2, parts[0] == Self.algorithm, let blob = Data(base64Encoded: String(parts[1])) else { return nil }
    var r = SSHWireReader(blob)
    guard (try? r.string()) == Data(Self.algorithm.utf8), (try? r.string()) == Data(Self.curve.utf8),
      let point = try? r.string(), let key = try? SSHPublicKey(p256: point)
    else { return nil }
    self = key
  }
}
