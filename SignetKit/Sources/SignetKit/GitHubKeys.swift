import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// The device's keys on the person's GitHub account. GitHub verifies SSH-signed commits only against
/// an account's signing keys, a list apart from the keys that authenticate, so the SSH key goes on
/// both (signet-update-brief.md step 5).
/// The token comes from `GitHubSignIn`.
public struct GitHubKeys: Sendable {
  public struct User: Codable, Sendable, Equatable {
    public let username: String
    public let avatarUrl: String

    enum CodingKeys: String, CodingKey {
      case username = "login"
      case avatarUrl = "avatar_url"
    }
  }

  public enum Failure: Error, Equatable, CustomStringConvertible {
    /// GitHub answered with this status and message.
    case answered(Int, String)

    public var description: String {
      switch self {
      case .answered(let status, let message): "GitHub answered \(status): \(message)"
      }
    }
  }

  private let token: String
  private let session: URLSession
  private let base = URL(string: "https://api.github.com")!

  public init(token: String, session: URLSession = .shared) {
    self.token = token
    self.session = session
  }

  public func user() async throws -> User {
    let data = try await call("GET", "/user", nil)
    return try JSONDecoder().decode(User.self, from: data)
  }

  /// Adds an SSH public key line as a signing key and as an authentication key.
  public func addSSHKey(_ line: String, title: String) async throws {
    try await add("/user/ssh_signing_keys", ["title": title, "key": line])
    try await add("/user/keys", ["title": title, "key": line])
  }

  public func addGPGKey(armored: String, title: String) async throws {
    try await add("/user/gpg_keys", ["name": title, "armored_public_key": armored])
  }

  public func addEmail(_ email: String) async throws {
    try await add("/user/emails", ["emails": [email]])
  }

  // MARK: -

  /// A key or email GitHub already has (422) is where it should be.
  private func add(_ path: String, _ body: [String: Any]) async throws {
    do {
      _ = try await call("POST", path, body)
    } catch Failure.answered(422, let message) where message.contains("already") {
      return
    }
  }

  private func call(_ method: String, _ path: String, _ body: [String: Any]?) async throws -> Data {
    var request = URLRequest(url: base.appendingPathComponent(path))
    request.httpMethod = method
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    if let body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }
    let (data, response) = try await session.data(for: request)
    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200..<300).contains(status) else { throw Failure.answered(status, Self.message(data)) }
    return data
  }

  /// GitHub's message, with each error's own message after it ("key is already in use").
  private static func message(_ data: Data) -> String {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return String(decoding: data, as: UTF8.self)
    }
    var parts = [json["message"] as? String ?? ""]
    for e in json["errors"] as? [[String: Any]] ?? [] {
      if let m = e["message"] as? String { parts.append(m) }
    }
    return parts.filter { !$0.isEmpty }.joined(separator: ": ")
  }
}
