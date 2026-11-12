import Foundation

/// Git's own signing, pointed at Signet in SSH's format (signet-update-brief.md step 4; spec 141
/// CG-126): `gpg.format ssh`, the device's public key, `commit.gpgsign` and `tag.gpgsign`, and as
/// `gpg.ssh.program` a small program that reaches Signet's socket, so apps that don't pass
/// SSH_AUTH_SOCK on (Xcode, Tower) sign too. A signing setup the person already has (GPG, or
/// another SSH key) is left alone unless they choose to replace it.
public struct GitSigning: Sendable {
  public enum Status: Sendable, Equatable {
    /// Git doesn't sign commits.
    case notSigning
    /// Git signs commits with a key that isn't Signet's: GPG, or another SSH key.
    case signingWithAnotherKey
    /// Git signs commits with Signet's key in SSH's format.
    case signingWithSignet
  }

  public enum Outcome: Sendable, Equatable {
    case configured
    /// Git already signs with another key, so nothing was changed.
    case leftAlone
  }

  private let environment: [String: String]

  /// - Parameter environment: The environment git runs with; its global config is the one changed.
  public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    self.environment = environment
  }

  public func current(publicKey: SSHPublicKey) throws -> Status {
    guard try get("commit.gpgsign") == "true" else { return .notSigning }
    let format = try get("gpg.format") ?? "openpgp"
    guard format == "ssh", let key = try get("user.signingkey"), names(key, publicKey) else {
      return .signingWithAnotherKey
    }
    return .signingWithSignet
  }

  /// Writes `signet.pub` and `signet-sign` in `folder` and points git at them, unless git already
  /// signs with another key and `replace` is false.
  @discardableResult
  public func setUp(publicKey: SSHPublicKey, socket: String, folder: String, replace: Bool) throws -> Outcome {
    if try current(publicKey: publicKey) == .signingWithAnotherKey, !replace { return .leftAlone }
    try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
    let keyFile = folder + "/signet.pub"
    try (publicKey.line + " Signet\n").write(toFile: keyFile, atomically: true, encoding: .utf8)
    let program = folder + "/signet-sign"
    let script = """
      #!/bin/sh
      # Signs for git through Signet's socket, for apps that don't pass SSH_AUTH_SOCK on.
      SSH_AUTH_SOCK=\(shellQuoted(socket)) exec /usr/bin/ssh-keygen "$@"

      """
    try script.write(toFile: program, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: program)
    try set("gpg.format", "ssh")
    try set("user.signingkey", keyFile)
    try set("gpg.ssh.program", program)
    try set("commit.gpgsign", "true")
    try set("tag.gpgsign", "true")
    return .configured
  }

  // MARK: -

  /// Whether git's `user.signingkey` names this key: as a `key::` literal, a public key line, or
  /// a file holding one (git's three ways).
  private func names(_ signingKey: String, _ key: SSHPublicKey) -> Bool {
    if signingKey.hasPrefix("key::") { return SSHPublicKey(line: String(signingKey.dropFirst(5))) == key }
    if let literal = SSHPublicKey(line: signingKey) { return literal == key }
    var path = signingKey
    if path.hasPrefix("~/"), let home = environment["HOME"] { path = home + path.dropFirst(1) }
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return false }
    return SSHPublicKey(line: text) == key
  }

  private func shellQuoted(_ s: String) -> String { "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }

  private func get(_ name: String) throws -> String? {
    let (status, out) = try git(["config", "--global", "--get", name])
    guard status == 0 else { return nil }
    return out.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func set(_ name: String, _ value: String) throws {
    let (status, _) = try git(["config", "--global", name, value])
    guard status == 0 else { throw SignetError.system("git config \(name)", status) }
  }

  private func git(_ args: [String]) throws -> (Int32, String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = ["git"] + args
    var env = environment
    env["PATH"] = env["PATH"] ?? "/usr/bin:/bin"
    p.environment = env
    let out = Pipe()
    // A git started meanwhile by another thread must not hold this pipe open (see closeOnExec).
    closeOnExec(out.fileHandleForReading.fileDescriptor)
    closeOnExec(out.fileHandleForWriting.fileDescriptor)
    p.standardOutput = out
    p.standardError = FileHandle.nullDevice
    try p.run()
    let data = out.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus, String(decoding: data, as: UTF8.self))
  }
}
