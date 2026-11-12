import Crypto
import Foundation

/// The device's key as a `secp256r1` Keeta account (signet-update-brief.md step 8; spec 141
/// CG-121): its address, and statements signed as such an account's signature verifies, P1363 r‖s
/// over the SHA3-256 digest of the data.
public enum KeetaAccount {
  /// The account's address, as the Keeta SDK writes it: `keeta_`, then lowercase unpadded base32
  /// of the compressed public key and the first five bytes of its SHA3-256 digest.
  public static func address(publicKey x963: Data) throws -> String {
    let point = try P256.Signing.PublicKey(x963Representation: x963)
    let compressed = point.compressedRepresentation
    let checksum = sha3_256(compressed).prefix(5)
    return "keeta_" + base32(compressed + checksum)
  }

  /// Signs `statement` with the device's key, as its Keeta account.
  public static func sign(_ statement: Data, with key: any SignetKey, reason: String) throws -> Data {
    let signature = try key.signature(forDigest: sha3_256(statement), reason: reason)
    guard signature.count == 64 else { throw SignetError.badSignature }
    return signature
  }

  /// SHA3-256 (FIPS 202), which CryptoKit doesn't have.
  public static func sha3_256(_ data: Data) -> Data { Keccak.sha3_256(data) }

  private static func base32(_ data: Data) -> String {
    let alphabet = Array("abcdefghijklmnopqrstuvwxyz234567")
    var out = ""
    var buffer = 0
    var bits = 0
    for byte in data {
      buffer = buffer << 8 | Int(byte)
      bits += 8
      while bits >= 5 {
        out.append(alphabet[(buffer >> (bits - 5)) & 31])
        bits -= 5
      }
      buffer &= (1 << bits) - 1
    }
    if bits > 0 { out.append(alphabet[(buffer << (5 - bits)) & 31]) }
    return out
  }
}

/// Keccak-f[1600] and the SHA3-256 sponge over it.
enum Keccak {
  private static let roundConstants: [UInt64] = [
    0x0000_0000_0000_0001, 0x0000_0000_0000_8082, 0x8000_0000_0000_808A, 0x8000_0000_8000_8000,
    0x0000_0000_0000_808B, 0x0000_0000_8000_0001, 0x8000_0000_8000_8081, 0x8000_0000_0000_8009,
    0x0000_0000_0000_008A, 0x0000_0000_0000_0088, 0x0000_0000_8000_8009, 0x0000_0000_8000_000A,
    0x0000_0000_8000_808B, 0x8000_0000_0000_008B, 0x8000_0000_0000_8089, 0x8000_0000_0000_8003,
    0x8000_0000_0000_8002, 0x8000_0000_0000_0080, 0x0000_0000_0000_800A, 0x8000_0000_8000_000A,
    0x8000_0000_8000_8081, 0x8000_0000_0000_8080, 0x0000_0000_8000_0001, 0x8000_0000_8000_8008,
  ]
  private static let rotations: [Int] = [
    0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14,
  ]

  private static func rotl(_ x: UInt64, _ n: Int) -> UInt64 { n == 0 ? x : (x << UInt64(n)) | (x >> UInt64(64 - n)) }

  private static func permute(_ a: inout [UInt64]) {
    var c = [UInt64](repeating: 0, count: 5)
    var b = [UInt64](repeating: 0, count: 25)
    for rc in roundConstants {
      for x in 0..<5 { c[x] = a[x] ^ a[x + 5] ^ a[x + 10] ^ a[x + 15] ^ a[x + 20] }
      for x in 0..<5 {
        let d = c[(x + 4) % 5] ^ rotl(c[(x + 1) % 5], 1)
        for y in 0..<5 { a[x + 5 * y] ^= d }
      }
      for x in 0..<5 {
        for y in 0..<5 { b[y + 5 * ((2 * x + 3 * y) % 5)] = rotl(a[x + 5 * y], rotations[x + 5 * y]) }
      }
      for x in 0..<5 {
        for y in 0..<5 { a[x + 5 * y] = b[x + 5 * y] ^ (~b[(x + 1) % 5 + 5 * y] & b[(x + 2) % 5 + 5 * y]) }
      }
      a[0] ^= rc
    }
  }

  static func sha3_256(_ data: Data) -> Data {
    let rate = 136
    var message = [UInt8](data)
    message.append(0x06)
    while message.count % rate != 0 { message.append(0) }
    message[message.count - 1] |= 0x80
    var state = [UInt64](repeating: 0, count: 25)
    for block in stride(from: 0, to: message.count, by: rate) {
      for i in 0..<(rate / 8) {
        var lane: UInt64 = 0
        for j in 0..<8 { lane |= UInt64(message[block + i * 8 + j]) << UInt64(8 * j) }
        state[i] ^= lane
      }
      permute(&state)
    }
    var out = Data(capacity: 32)
    for i in 0..<4 {
      for j in 0..<8 { out.append(UInt8(truncatingIfNeeded: state[i] >> UInt64(8 * j))) }
    }
    return out
  }
}
