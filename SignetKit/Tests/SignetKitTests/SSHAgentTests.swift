// Signet's SSH agent, served on a real socket and asked by OpenSSH's own tools: `ssh-add -L` lists
// the key and `ssh-keygen -Y sign` signs with it, as git does in SSH's format.
import Crypto
import Foundation
import SignetKit
import Testing

@Suite(.serialized) struct SSHAgentTests {
  @Test func publicKeyLineAndFingerprintAreOpenSSHs() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let key = MemoryKey()
    let pem = dir + "/key.pem"
    try key.privateKey.publicKey.pemRepresentation.write(toFile: pem, atomically: true, encoding: .utf8)
    let converted = try run(["ssh-keygen", "-i", "-m", "PKCS8", "-f", pem])
    #expect(converted.status == 0, "\(converted.err)")

    let ssh = try SSHPublicKey(p256: key.publicKey)
    #expect(ssh.line == converted.out.trimmingCharacters(in: .whitespacesAndNewlines))
    try (ssh.line + "\n").write(toFile: dir + "/key.pub", atomically: true, encoding: .utf8)
    let listed = try run(["ssh-keygen", "-l", "-E", "sha256", "-f", dir + "/key.pub"])
    #expect(listed.out.split(separator: " ")[1] == Substring(ssh.fingerprint))
  }

  @Test func sshAddListsTheKeysTheAgentServes() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let keys = [MemoryKey(), MemoryKey()]
    let socket = SignetSocket(path: dir + "/agent.sock", agent: SSHAgent(keys: { keys }))
    #expect(try socket.start() == .serving)
    defer { socket.stop() }

    let listed = try run(["ssh-add", "-L"], environment: ["SSH_AUTH_SOCK": dir + "/agent.sock"])
    #expect(listed.status == 0, "\(listed.err)")
    let lines = listed.out.split(separator: "\n").map { $0.split(separator: " ").prefix(2).joined(separator: " ") }
    #expect(lines == keys.map { try! SSHPublicKey(p256: $0.publicKey).line })
  }

  @Test func sshKeygenSignsThroughTheAgentAndTheSignatureVerifies() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let key = MemoryKey()
    let line = try SSHPublicKey(p256: key.publicKey).line
    let socket = SignetSocket(path: dir + "/agent.sock", agent: SSHAgent(keys: { [key] }))
    try socket.start()
    defer { socket.stop() }
    try (line + "\n").write(toFile: dir + "/key.pub", atomically: true, encoding: .utf8)
    try Data("a commit".utf8).write(to: URL(fileURLWithPath: dir + "/message"))

    let signed = try run(
      ["ssh-keygen", "-Y", "sign", "-n", "git", "-f", dir + "/key.pub", dir + "/message"],
      environment: ["SSH_AUTH_SOCK": dir + "/agent.sock"])
    #expect(signed.status == 0, "\(signed.err)")
    try "me@example.com \(line)\n".write(toFile: dir + "/allowed", atomically: true, encoding: .utf8)
    let verified = try run(
      ["ssh-keygen", "-Y", "verify", "-f", dir + "/allowed", "-I", "me@example.com", "-n", "git", "-s", dir + "/message.sig"],
      input: Data("a commit".utf8))
    #expect(verified.status == 0, "\(verified.err)")
    #expect(key.reasons.count == 1)
  }

  @Test func theProcessThatAskedIsNamedInTheReason() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let key = MemoryKey()
    let socket = SignetSocket(
      path: dir + "/agent.sock", agent: SSHAgent(keys: { [key] }, processName: { _ in "Tower" }))
    try socket.start()
    defer { socket.stop() }
    try (SSHPublicKey(p256: key.publicKey).line + "\n").write(toFile: dir + "/key.pub", atomically: true, encoding: .utf8)
    try Data("x".utf8).write(to: URL(fileURLWithPath: dir + "/m"))
    try run(["ssh-keygen", "-Y", "sign", "-n", "git", "-f", dir + "/key.pub", dir + "/m"], environment: ["SSH_AUTH_SOCK": dir + "/agent.sock"])
    #expect(key.reasons == ["sign a request from \"Tower\""])
  }

  /// Keeta Agent's GnuPG bridge (libssh-agent-pkcs11-provider) sends a digest it hashed itself,
  /// flagged 0x40000000; the agent signs it as given, or GPG signatures made through it break.
  @Test func aDigestFlaggedByTheGnuPGBridgeIsSignedAsGiven() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let key = MemoryKey()
    let socket = SignetSocket(path: dir + "/agent.sock", agent: SSHAgent(keys: { [key] }))
    try socket.start()
    defer { socket.stop() }

    let digest = Data(SHA256.hash(data: Data("an OpenPGP signature's hashed data".utf8)))
    let blob = try SSHPublicKey(p256: key.publicKey).blob
    var request = Data([13])
    request.append(sshString(blob))
    request.append(sshString(digest))
    request.append(contentsOf: [0x40, 0, 0, 0])
    let reply = try exchange(dir + "/agent.sock", request)

    #expect(reply.first == 14)
    var r = SSHReader(reply.dropFirst())
    var sig = SSHReader(try r.string())
    #expect(String(decoding: try sig.string(), as: UTF8.self) == "ecdsa-sha2-nistp256")
    var rs = SSHReader(try sig.string())
    let raw = mpint32(try rs.string()) + mpint32(try rs.string())
    #expect(key.verifies(raw, digest: digest))
  }

  @Test func aKeyTheAgentDoesNotHoldIsRefused() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let socket = SignetSocket(path: dir + "/agent.sock", agent: SSHAgent(keys: { [MemoryKey()] }))
    try socket.start()
    defer { socket.stop() }
    var request = Data([13])
    request.append(sshString(try SSHPublicKey(p256: MemoryKey().publicKey).blob))
    request.append(sshString(Data("data".utf8)))
    request.append(contentsOf: [0, 0, 0, 0])
    #expect(try exchange(dir + "/agent.sock", request) == Data([5]))
  }
}

// MARK: - The wire, written here independently of SignetKit's own writer

func sshString(_ data: Data) -> Data {
  var n = UInt32(data.count).bigEndian
  return Data(bytes: &n, count: 4) + data
}

struct SSHReader {
  var rest: Data
  init<D: DataProtocol>(_ d: D) { rest = Data(d) }
  mutating func string() throws -> Data {
    guard rest.count >= 4 else { throw CocoaError(.coderReadCorrupt) }
    let n = rest.prefix(4).reduce(0) { $0 << 8 | Int($1) }
    guard rest.count >= 4 + n else { throw CocoaError(.coderReadCorrupt) }
    let s = rest.dropFirst(4).prefix(n)
    rest = rest.dropFirst(4 + n)
    return Data(s)
  }
}

/// An mpint's magnitude as 32 big-endian bytes.
func mpint32(_ d: Data) -> Data {
  let trimmed = d.drop(while: { $0 == 0 })
  return Data(repeating: 0, count: 32 - trimmed.count) + trimmed
}
