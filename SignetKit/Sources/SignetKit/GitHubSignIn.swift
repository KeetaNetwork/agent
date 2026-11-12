import Foundation

/// Signing in to GitHub through Signet's OAuth App, which Workspace serves at app.keeta.ai since
/// agent.keeta.com was retired (Workspace spec 143). The person approves Signet on GitHub, and
/// Workspace sends them back to `keeta-agent://` with their token, or the reason there is none,
/// and the state this sign-in sent. Workspace keeps nothing; Signet calls GitHub itself
/// (`GitHubKeys`).
public struct GitHubSignIn: Sendable, Equatable {
  /// What `GitHubKeys` needs: the person's profile and emails, and their SSH, GPG and SSH signing keys.
  public static let scopes = ["user", "write:public_key", "write:gpg_key", "write:ssh_signing_key"]
  static let login = "https://app.keeta.ai/api/public/signet/github/login"

  /// Sent with the sign-in and carried back, so only the link this sign-in started is acted on.
  /// Workspace accepts letters, digits, `_` and `-`, up to 100 characters.
  public let state: String

  public init(state: String = UUID().uuidString) {
    self.state = state
  }

  /// Where the person signs in.
  public var url: URL {
    var c = URLComponents(string: Self.login)!
    c.queryItems = [
      URLQueryItem(name: "scopes", value: Self.scopes.joined(separator: ",")),
      URLQueryItem(name: "state", value: state),
    ]
    return c.url!
  }

  public enum Outcome: Sendable, Equatable {
    case signedIn(token: String)
    /// GitHub or Workspace said no; the words say why, for the person.
    case refused(String)
  }

  /// What a `keeta-agent://` link says about this sign-in, or nil when the link isn't this sign-in's.
  public func outcome(of link: URL) -> Outcome? {
    let items = URLComponents(url: link, resolvingAgainstBaseURL: false)?.queryItems ?? []
    func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
    guard value("state") == state else { return nil }
    if let token = value("token"), !token.isEmpty { return .signedIn(token: token) }
    switch value("error") {
    case "access_denied": return .refused("You didn’t allow Signet on GitHub, so your keys weren’t added.")
    case "exchange_failed": return .refused("GitHub couldn’t finish signing you in. Try again.")
    default: return .refused("Signing in to GitHub didn’t finish. Try again.")
    }
  }
}
