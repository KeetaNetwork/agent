// What the tests share: a P-256 key in memory standing in for the Secure Enclave's (which no CI
// machine has), the real OpenSSH and git tools, and short temporary folders (a Unix socket's path
// must fit in about 100 bytes).
import Crypto
import Foundation
import SignetKit

#if canImport(Glibc)
  import Glibc
#elseif canImport(Darwin)
  import Darwin
#endif

/// A software P-256 key with SignetKey's contract: a raw r‖s signature over the digest it is given.
final class MemoryKey: SignetKey, @unchecked Sendable {
  let privateKey: P256.Signing.PrivateKey
  private let lock = NSLock()
  private var _reasons: [String] = []
  /// The reasons each signature was asked with, as Touch ID would show them.
  var reasons: [String] { lock.withLock { _reasons } }

  init(_ privateKey: P256.Signing.PrivateKey = .init()) { self.privateKey = privateKey }

  var publicKey: Data { privateKey.publicKey.x963Representation }

  func signature(forDigest digest: Data, reason: String) throws -> Data {
    lock.withLock { _reasons.append(reason) }
    return try privateKey.signature(for: RawDigest(digest)).rawRepresentation
  }

  /// Whether `signature` (raw r‖s) is this key's over `digest`.
  func verifies(_ signature: Data, digest: Data) -> Bool {
    guard let s = try? P256.Signing.ECDSASignature(rawRepresentation: signature) else { return false }
    return privateKey.publicKey.isValidSignature(s, for: RawDigest(digest))
  }
}

/// A 32-byte digest made elsewhere (SHA3-256, or one the GnuPG bridge hashed), for CryptoKit's API.
struct RawDigest: Digest {
  static let byteCount = 32
  let bytes: [UInt8]
  init(_ data: Data) {
    precondition(data.count == Self.byteCount)
    bytes = Array(data)
  }
  func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try bytes.withUnsafeBytes(body)
  }
  var description: String { bytes.map { String(format: "%02x", $0) }.joined() }
}

struct Ran {
  let status: Int32
  let out: String
  let err: String
}

/// Runs a tool by name from PATH, with exactly `environment` (plus PATH and HOME when not given).
@discardableResult
func run(
  _ arguments: [String], environment: [String: String] = [:], input: Data? = nil, in folder: String? = nil
) throws -> Ran {
  let p = Process()
  p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  p.arguments = arguments
  var env = environment
  env["PATH"] = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
  env["HOME"] = env["HOME"] ?? NSTemporaryDirectory()
  p.environment = env
  if let folder { p.currentDirectoryURL = URL(fileURLWithPath: folder) }
  let out = Pipe(), err = Pipe(), inp = Pipe()
  // Tests run in parallel, and on macOS a process started by one would otherwise inherit another's
  // pipes and hold them open, so neither reader ever sees the end.
  for pipe in [out, err, inp] {
    for fd in [pipe.fileHandleForReading.fileDescriptor, pipe.fileHandleForWriting.fileDescriptor] {
      _ = fcntl(fd, F_SETFD, fcntl(fd, F_GETFD) | FD_CLOEXEC)
    }
  }
  p.standardOutput = out
  p.standardError = err
  p.standardInput = inp
  try p.run()
  if let input { inp.fileHandleForWriting.write(input) }
  try inp.fileHandleForWriting.close()
  let o = out.fileHandleForReading.readDataToEndOfFile()
  let e = err.fileHandleForReading.readDataToEndOfFile()
  p.waitUntilExit()
  return Ran(status: p.terminationStatus, out: String(decoding: o, as: UTF8.self), err: String(decoding: e, as: UTF8.self))
}

/// A fresh folder under /tmp, short enough for socket paths, removed by the caller.
func shortTemporaryFolder() throws -> String {
  var template = Array("/tmp/signet-XXXXXX".utf8CString)
  guard let made = mkdtemp(&template) else { throw CocoaError(.fileWriteUnknown) }
  return String(cString: made)
}

func fixture(_ name: String) throws -> Data {
  guard let url = Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: nil) else {
    throw CocoaError(.fileNoSuchFile)
  }
  return try Data(contentsOf: url)
}

extension Data {
  init(hex: String) {
    var bytes = [UInt8]()
    var i = hex.startIndex
    while i < hex.endIndex {
      let j = hex.index(i, offsetBy: 2)
      bytes.append(UInt8(hex[i..<j], radix: 16)!)
      i = j
    }
    self.init(bytes)
  }
  var hex: String { map { String(format: "%02x", $0) }.joined() }
}

/// Polls `condition` until it holds or `seconds` pass.
func eventually(within seconds: Double, _ condition: () -> Bool) -> Bool {
  let end = Date().addingTimeInterval(seconds)
  while Date() < end {
    if condition() { return true }
    usleep(50_000)
  }
  return condition()
}

/// Sends one agent request over the socket at `path` and returns the reply's payload.
func exchange(_ path: String, _ payload: Data) throws -> Data {
  let fd = socket(AF_UNIX, Int32(SOCK_STREAM.rawValue_), 0)
  guard fd >= 0 else { throw POSIXError(.EIO) }
  defer { close(fd) }
  var addr = sockaddr_un()
  addr.sun_family = sa_family_t(AF_UNIX)
  withUnsafeMutableBytes(of: &addr.sun_path) { buf in
    for (i, b) in path.utf8.enumerated() { buf[i] = b }
  }
  let ok = withUnsafePointer(to: &addr) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
      connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
    }
  }
  guard ok == 0 else { throw POSIXError(.ECONNREFUSED) }
  let framed = sshString(payload)
  _ = framed.withUnsafeBytes { write(fd, $0.baseAddress, framed.count) }
  func read(_ n: Int) throws -> Data {
    var out = Data()
    var buf = [UInt8](repeating: 0, count: n)
    while out.count < n {
      let got = recv(fd, &buf, n - out.count, 0)
      guard got > 0 else { throw POSIXError(.EIO) }
      out.append(contentsOf: buf[0..<got])
    }
    return out
  }
  let length = try read(4).reduce(0) { $0 << 8 | Int($1) }
  return try read(length)
}

#if canImport(Glibc)
  extension __socket_type { var rawValue_: UInt32 { rawValue } }
#else
  extension Int32 { var rawValue_: Int32 { self } }
#endif

/// Binds a Unix socket at `path` and closes it without removing the file, as a process that crashed.
func leaveSocketBehind(at path: String) throws {
  let fd = socket(AF_UNIX, Int32(SOCK_STREAM.rawValue_), 0)
  var addr = sockaddr_un()
  addr.sun_family = sa_family_t(AF_UNIX)
  withUnsafeMutableBytes(of: &addr.sun_path) { buf in
    for (i, b) in path.utf8.enumerated() { buf[i] = b }
  }
  let ok = withUnsafePointer(to: &addr) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
      bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
    }
  }
  close(fd)
  guard ok == 0 else { throw POSIXError(.EADDRINUSE) }
}
