// One socket, whichever Signet runs serves it (signet-update-brief.md step 3; spec 141 CG-171): the
// standalone app and Workspace for Mac can be installed together, the second stands by while the
// first answers, and takes over within a few seconds once the first quits.
import Foundation
import SignetKit
import Testing

@Suite(.serialized) struct SocketHandOverTests {
  private func listed(_ path: String) throws -> String {
    try run(["ssh-add", "-L"], environment: ["SSH_AUTH_SOCK": path]).out
  }

  @Test func theSecondSignetStandsByWhileTheFirstAnswersAndTakesOverWhenItQuits() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let path = dir + "/agent.sock"
    let firstKey = MemoryKey()
    let first = SignetSocket(path: path, agent: SSHAgent(keys: { [firstKey] }))
    let key = MemoryKey()
    let second = SignetSocket(path: path, agent: SSHAgent(keys: { [key] }))
    defer { first.stop(); second.stop() }

    #expect(try first.start() == .serving)
    let firstLine = try listed(path)
    #expect(try second.start() == .standingBy)
    #expect(try listed(path) == firstLine, "the second must not replace the first's socket")

    second.watch(every: 0.2)
    first.stop()
    #expect(eventually(within: 3) { second.state == .serving })
    #expect(try listed(path).hasPrefix(try SSHPublicKey(p256: key.publicKey).line))
  }

  @Test func aSocketLeftBehindWithNothingServingItIsReplaced() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let path = dir + "/agent.sock"
    try leaveSocketBehind(at: path)  // as a Signet that crashed does
    #expect(FileManager.default.fileExists(atPath: path))

    let next = SignetSocket(path: path, agent: SSHAgent(keys: { [MemoryKey()] }))
    defer { next.stop() }
    #expect(try next.start() == .serving)
    #expect(try listed(path).hasPrefix("ecdsa-sha2-nistp256 "))
  }

  @Test func quittingReleasesTheSocket() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let path = dir + "/agent.sock"
    let s = SignetSocket(path: path, agent: SSHAgent(keys: { [MemoryKey()] }))
    try s.start()
    s.stop()
    #expect(!FileManager.default.fileExists(atPath: path))
    #expect(!SignetSocket.answers(at: path))
  }

  @Test func theFolderIsMadeAndOnlyItsOwnerCanReachTheSocket() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let path = dir + "/Signet/agent.sock"
    let s = SignetSocket(path: path, agent: SSHAgent(keys: { [MemoryKey()] }))
    defer { s.stop() }
    try s.start()
    let attrs = try FileManager.default.attributesOfItem(atPath: dir + "/Signet")
    #expect((attrs[.posixPermissions] as? Int ?? 0) & 0o077 == 0)
  }

  @Test func keetaAgentsOldPathLeadsToTheSocket() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let home = dir
    let path = SignetPaths.socket(home: home)
    let legacy = SignetPaths.keetaAgentSocket(home: home)
    #expect(path == home + "/Library/Signet/agent.sock")
    #expect(legacy == home + "/Library/KeetaAgent/Data/socket.ssh")

    let key = MemoryKey()
    let s = SignetSocket(path: path, agent: SSHAgent(keys: { [key] }))
    defer { s.stop() }
    try s.start()
    try s.link(from: legacy)
    #expect(try listed(legacy) == listed(path))
    try s.link(from: legacy)  // again: nothing changes, nothing fails
    #expect(try listed(legacy) == listed(path))
  }

  @Test func anOldKeetaAgentStillServingItsPathIsLeftAlone() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let legacy = SignetPaths.keetaAgentSocket(home: dir)
    let oldKey = MemoryKey()
    let old = SignetSocket(path: legacy, agent: SSHAgent(keys: { [oldKey] }))
    defer { old.stop() }
    try old.start()
    let oldLine = try listed(legacy)

    let s = SignetSocket(path: SignetPaths.socket(home: dir), agent: SSHAgent(keys: { [MemoryKey()] }))
    defer { s.stop() }
    try s.start()
    try s.link(from: legacy)
    #expect(try listed(legacy) == oldLine)
  }
}
