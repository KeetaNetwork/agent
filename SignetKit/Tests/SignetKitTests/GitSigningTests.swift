// Git signs in SSH's format through Signet (signet-update-brief.md step 4; spec 141 CG-126 and
// CG-172): real git, with a global config of the test's own, commits through Signet's socket even
// when SSH_AUTH_SOCK isn't passed on (Xcode, Tower), and a signing setup the person already has is
// left alone unless they replace it.
import Foundation
import SignetKit
import Testing

@Suite(.serialized) struct GitSigningTests {
  struct Home {
    let dir: String
    let key = MemoryKey()
    let socket: SignetSocket
    var env: [String: String] {
      ["HOME": dir, "GIT_CONFIG_GLOBAL": dir + "/gitconfig", "GIT_CONFIG_NOSYSTEM": "1"]
    }
    var folder: String { dir + "/Library/Signet" }

    init() throws {
      dir = try shortTemporaryFolder()
      let key = self.key
      socket = SignetSocket(path: SignetPaths.socket(home: dir), agent: SSHAgent(keys: { [key] }))
      try socket.start()
      FileManager.default.createFile(atPath: dir + "/gitconfig", contents: Data())
    }
    func close() {
      socket.stop()
      try? FileManager.default.removeItem(atPath: dir)
    }
    func git(_ args: String..., in repo: String? = nil) throws -> Ran {
      try run(["git"] + args, environment: env, in: repo)
    }
    func config(_ name: String) throws -> String {
      try git("config", "--global", "--get", name).out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var setup: GitSigning { GitSigning(environment: env) }
    var publicKey: SSHPublicKey { try! SSHPublicKey(p256: key.publicKey) }
  }

  @Test func aCommitIsSignedThroughSignetWithoutSSHAuthSockAndVerifies() throws {
    let h = try Home()
    defer { h.close() }
    let outcome = try h.setup.setUp(publicKey: h.publicKey, socket: h.socket.path, folder: h.folder, replace: false)
    #expect(outcome == .configured)
    #expect(try h.config("gpg.format") == "ssh")
    #expect(try h.config("commit.gpgsign") == "true")
    #expect(try h.config("tag.gpgsign") == "true")

    let repo = h.dir + "/repo"
    try FileManager.default.createDirectory(atPath: repo, withIntermediateDirectories: true)
    #expect(try h.git("init", "-q", in: repo).status == 0)
    let commit = try h.git("-c", "user.name=Me", "-c", "user.email=me@example.com", "commit", "-q", "--allow-empty", "-m", "signed", in: repo)
    #expect(commit.status == 0, "\(commit.err)")

    try "me@example.com \(h.publicKey.line)\n".write(toFile: h.dir + "/allowed", atomically: true, encoding: .utf8)
    let verified = try h.git("-c", "gpg.ssh.allowedSignersFile=\(h.dir)/allowed", "verify-commit", "HEAD", in: repo)
    #expect(verified.status == 0, "\(verified.err)")
    #expect(h.key.reasons.count == 1)
  }

  @Test func aGPGSetupThePersonAlreadyHasIsLeftAlone() throws {
    let h = try Home()
    defer { h.close() }
    _ = try h.git("config", "--global", "commit.gpgsign", "true")
    _ = try h.git("config", "--global", "user.signingkey", "78A10AF1481016DC")
    let before = try String(contentsOfFile: h.dir + "/gitconfig", encoding: .utf8)

    let outcome = try h.setup.setUp(publicKey: h.publicKey, socket: h.socket.path, folder: h.folder, replace: false)
    #expect(outcome == .leftAlone)
    #expect(try String(contentsOfFile: h.dir + "/gitconfig", encoding: .utf8) == before)
  }

  @Test func replacingPointsGitAtSignetInstead() throws {
    let h = try Home()
    defer { h.close() }
    _ = try h.git("config", "--global", "commit.gpgsign", "true")
    _ = try h.git("config", "--global", "user.signingkey", "78A10AF1481016DC")
    #expect(try h.setup.setUp(publicKey: h.publicKey, socket: h.socket.path, folder: h.folder, replace: true) == .configured)
    #expect(try h.config("gpg.format") == "ssh")
    #expect(try String(contentsOfFile: h.config("user.signingkey"), encoding: .utf8).hasPrefix(h.publicKey.line))
  }

  /// `workspace signet setup` (CG-126) may have pointed git at the same key through a file of its
  /// own; that is this key, so setting up again takes it over rather than leaving it alone.
  @Test func theSameKeyNamedByAnotherFileCountsAsSignets() throws {
    let h = try Home()
    defer { h.close() }
    let other = h.dir + "/elsewhere.pub"
    try (h.publicKey.line + " Signet\n").write(toFile: other, atomically: true, encoding: .utf8)
    _ = try h.git("config", "--global", "gpg.format", "ssh")
    _ = try h.git("config", "--global", "user.signingkey", other)
    _ = try h.git("config", "--global", "commit.gpgsign", "true")
    #expect(try h.setup.setUp(publicKey: h.publicKey, socket: h.socket.path, folder: h.folder, replace: false) == .configured)
    #expect(try h.config("gpg.ssh.program").hasPrefix(h.folder))
  }

  @Test func readsWhetherGitSignsWithSignet() throws {
    let h = try Home()
    defer { h.close() }
    #expect(try h.setup.current(publicKey: h.publicKey) == .notSigning)
    _ = try h.git("config", "--global", "commit.gpgsign", "true")
    #expect(try h.setup.current(publicKey: h.publicKey) == .signingWithAnotherKey)
    _ = try h.setup.setUp(publicKey: h.publicKey, socket: h.socket.path, folder: h.folder, replace: true)
    #expect(try h.setup.current(publicKey: h.publicKey) == .signingWithSignet)
  }
}
