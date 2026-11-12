import Foundation

/// A P-256 signing key that never leaves the device: the Secure Enclave's on a Mac
/// (`SecureEnclaveKey`). Everything Signet signs, SSH's format and Keeta statements alike, comes
/// down to one signature over a 32-byte digest, so the key itself never sees the formats.
public protocol SignetKey: Sendable {
  /// The public key, as X9.63 uncompressed bytes (65 bytes, starting 0x04).
  var publicKey: Data { get }
  /// The ECDSA signature over `digest` (32 bytes, already hashed), raw r‖s (64 bytes). `reason`
  /// finishes the sentence the Touch ID prompt shows ("… to sign a request from "git"").
  func signature(forDigest digest: Data, reason: String) throws -> Data
}

public enum SignetError: Error, Equatable, CustomStringConvertible {
  /// A public key that isn't an uncompressed P-256 point.
  case notP256
  /// A signature that isn't 64 bytes of r‖s.
  case badSignature
  /// A socket path longer than a Unix socket's address holds.
  case pathTooLong(String)
  /// A system call failed with `errno`.
  case system(String, Int32)
  /// Bytes on the SSH agent's wire that don't parse.
  case malformed

  public var description: String {
    switch self {
    case .notP256: "The key isn't a P-256 public key."
    case .badSignature: "The key gave a signature that isn't P-256's."
    case .pathTooLong(let p): "The socket path is too long: \(p)"
    case .system(let call, let errno): "\(call) failed: \(String(cString: strerror(errno)))"
    case .malformed: "The request doesn't parse."
    }
  }
}
