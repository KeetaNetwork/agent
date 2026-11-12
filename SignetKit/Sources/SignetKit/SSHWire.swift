import Foundation

/// SSH's wire encoding (RFC 4251 §5): strings with a 32-bit big-endian length, and mpints.
enum SSHWire {
  static func string(_ data: Data) -> Data { uint32(UInt32(data.count)) + data }
  static func string(_ text: String) -> Data { string(Data(text.utf8)) }

  static func uint32(_ n: UInt32) -> Data {
    Data([UInt8(n >> 24 & 0xff), UInt8(n >> 16 & 0xff), UInt8(n >> 8 & 0xff), UInt8(n & 0xff)])
  }

  /// A non-negative integer from big-endian bytes, as an mpint: no needless leading zeros, and a
  /// zero byte in front when the top bit is set so it doesn't read as negative.
  static func mpint(_ magnitude: Data) -> Data {
    var m = Data(magnitude.drop(while: { $0 == 0 }))
    if let first = m.first, first & 0x80 != 0 { m.insert(0, at: 0) }
    return string(m)
  }

  /// The ECDSA signature blob SSH carries: the algorithm's name, then r and s as mpints.
  static func ecdsaSignature(raw: Data) throws -> Data {
    guard raw.count == 64 else { throw SignetError.badSignature }
    let rs = mpint(raw.prefix(32)) + mpint(raw.suffix(32))
    return string(SSHPublicKey.algorithm) + string(rs)
  }
}

/// Reads SSH's wire encoding from the front of some bytes.
struct SSHWireReader {
  private(set) var rest: Data

  init(_ data: Data) { rest = Data(data) }

  mutating func byte() throws -> UInt8 {
    guard let b = rest.first else { throw SignetError.malformed }
    rest = Data(rest.dropFirst())
    return b
  }

  mutating func uint32() throws -> UInt32 {
    guard rest.count >= 4 else { throw SignetError.malformed }
    let n = rest.prefix(4).reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
    rest = Data(rest.dropFirst(4))
    return n
  }

  mutating func string() throws -> Data {
    let n = Int(try uint32())
    guard rest.count >= n else { throw SignetError.malformed }
    let s = Data(rest.prefix(n))
    rest = Data(rest.dropFirst(n))
    return s
  }
}
