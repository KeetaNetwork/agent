// Signatures in SSH's format (SSHSIG) made in-process, as Workspace's device registration asks for
// (spec 141 CG-121: the challenge, namespace `workspace-signet`), checked by OpenSSH itself.
import Foundation
import SignetKit
import Testing

@Suite struct SSHSignatureTests {
  private func check(_ armored: String, _ message: Data, key: MemoryKey, namespace: String, in dir: String) throws -> Ran {
    try armored.write(toFile: dir + "/sig", atomically: true, encoding: .utf8)
    let line = try SSHPublicKey(p256: key.publicKey).line
    try "device \(line)\n".write(toFile: dir + "/allowed", atomically: true, encoding: .utf8)
    return try run(
      ["ssh-keygen", "-Y", "verify", "-f", dir + "/allowed", "-I", "device", "-n", namespace, "-s", dir + "/sig"],
      input: message)
  }

  @Test func aChallengeSignedForWorkspaceVerifiesWithSSHKeygen() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let key = MemoryKey()
    let challenge = Data("wsc_3kF9a0b1c2d3e4f5".utf8)
    let armored = try SSHSignature.armored(challenge, namespace: "workspace-signet", key: key, reason: "register this Mac with Workspace")

    #expect(armored.hasPrefix("-----BEGIN SSH SIGNATURE-----\n"))
    #expect(armored.hasSuffix("-----END SSH SIGNATURE-----\n"))
    #expect(armored.split(separator: "\n").allSatisfy { $0.count <= 70 })
    let ok = try check(armored, challenge, key: key, namespace: "workspace-signet", in: dir)
    #expect(ok.status == 0, "\(ok.err)")
    #expect(key.reasons == ["register this Mac with Workspace"])
  }

  @Test func itHoldsOnlyInItsNamespaceAndForItsMessage() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let key = MemoryKey()
    let armored = try SSHSignature.armored(Data("one".utf8), namespace: "workspace-signet", key: key, reason: "r")
    #expect(try check(armored, Data("one".utf8), key: key, namespace: "git", in: dir).status != 0)
    #expect(try check(armored, Data("two".utf8), key: key, namespace: "workspace-signet", in: dir).status != 0)
  }
}
