import Crypto
import Foundation

/// Signatures in SSH's format (OpenSSH PROTOCOL.sshsig), as `ssh-keygen -Y sign` writes them, made
/// in-process with the device's key: Workspace's device registration signs its challenge this way
/// in the namespace `workspace-signet` (spec 141 CG-121).
public enum SSHSignature {
  static let magic = Data("SSHSIG".utf8)
  static let hashAlgorithm = "sha512"

  /// The armored signature of `message` in `namespace`.
  public static func armored(_ message: Data, namespace: String, key: any SignetKey, reason: String) throws -> String {
    let publicKey = try SSHPublicKey(p256: key.publicKey)
    let signed =
      magic + SSHWire.string(namespace) + SSHWire.string("") + SSHWire.string(hashAlgorithm)
      + SSHWire.string(Data(SHA512.hash(data: message)))
    let raw = try key.signature(forDigest: Data(SHA256.hash(data: signed)), reason: reason)
    let blob =
      magic + SSHWire.uint32(1) + SSHWire.string(publicKey.blob) + SSHWire.string(namespace) + SSHWire.string("")
      + SSHWire.string(hashAlgorithm) + SSHWire.string(try SSHWire.ecdsaSignature(raw: raw))
    let b64 = blob.base64EncodedString()
    var lines = ["-----BEGIN SSH SIGNATURE-----"]
    var i = b64.startIndex
    while i < b64.endIndex {
      let j = b64.index(i, offsetBy: 70, limitedBy: b64.endIndex) ?? b64.endIndex
      lines.append(String(b64[i..<j]))
      i = j
    }
    lines.append("-----END SSH SIGNATURE-----")
    return lines.joined(separator: "\n") + "\n"
  }
}
