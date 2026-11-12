import Crypto
import Foundation

/// The SSH agent protocol (draft-miller-ssh-agent §4.4, §4.5) over Signet's keys: listing them and
/// signing with them. Everything else is answered with a failure.
public final class SSHAgent: Sendable {
  private let keys: @Sendable () -> [any SignetKey]
  private let processName: (@Sendable (Int32) -> String?)?

  /// - Parameters:
  ///   - keys: The keys to serve, read at each request (a key made later is served at once).
  ///   - processName: The app behind a connection's process id, for the Touch ID prompt.
  public init(keys: @escaping @Sendable () -> [any SignetKey], processName: (@Sendable (Int32) -> String?)? = nil) {
    self.keys = keys
    self.processName = processName
  }

  enum Message: UInt8 {
    case failure = 5
    case requestIdentities = 11
    case identitiesAnswer = 12
    case signRequest = 13
    case signResponse = 14
  }

  /// Keeta Agent's GnuPG bridge (libssh-agent-pkcs11-provider, patched) sets this flag on a sign
  /// request whose data is a digest it hashed itself, to be signed as given.
  static let rawDigestFlag: UInt32 = 0x4000_0000

  /// The reply to one request's payload (its length already read), without its length.
  func respond(to payload: Data, peer: Int32?) -> Data {
    var r = SSHWireReader(payload)
    do {
      switch Message(rawValue: try r.byte()) {
      case .requestIdentities:
        let served = try keys().map { try SSHPublicKey(p256: $0.publicKey) }
        var out = Data([Message.identitiesAnswer.rawValue]) + SSHWire.uint32(UInt32(served.count))
        for k in served { out += SSHWire.string(k.blob) + SSHWire.string("") }
        return out
      case .signRequest:
        let blob = try r.string()
        let data = try r.string()
        let flags = (try? r.uint32()) ?? 0
        guard let key = keys().first(where: { (try? SSHPublicKey(p256: $0.publicKey).blob) == blob }) else {
          return Data([Message.failure.rawValue])
        }
        let digest = flags & Self.rawDigestFlag != 0 ? data : Data(SHA256.hash(data: data))
        guard digest.count == 32 else { return Data([Message.failure.rawValue]) }
        let raw = try key.signature(forDigest: digest, reason: reason(peer))
        return Data([Message.signResponse.rawValue]) + SSHWire.string(try SSHWire.ecdsaSignature(raw: raw))
      default:
        return Data([Message.failure.rawValue])
      }
    } catch {
      return Data([Message.failure.rawValue])
    }
  }

  private func reason(_ peer: Int32?) -> String {
    if let peer, let name = processName?(peer) { return "sign a request from \"\(name)\"" }
    return "sign a request"
  }
}
