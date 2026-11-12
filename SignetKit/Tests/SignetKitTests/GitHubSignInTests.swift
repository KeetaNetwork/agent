// Signing in to GitHub through Signet's OAuth App, which Workspace serves at app.keeta.ai since
// agent.keeta.com was retired (Workspace spec 143). The link back to keeta-agent:// carries the
// person's token, or the reason it didn't come, and the state this sign-in sent.
import Foundation
import SignetKit
import Testing

struct GitHubSignInTests {
  let signIn = GitHubSignIn(state: "s1")

  func query(_ url: URL) -> [String: String] {
    Dictionary(uniqueKeysWithValues: URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!.map { ($0.name, $0.value ?? "") })
  }

  @Test func signingInGoesToWorkspaceWithTheKeyScopesAndState() {
    let url = signIn.url
    #expect(url.absoluteString.hasPrefix("https://app.keeta.ai/api/public/signet/github/login?"))
    let q = query(url)
    let scopes = q["scopes"]!.split(separator: ",")
    #expect(scopes.contains("write:ssh_signing_key"))
    #expect(scopes.contains("write:gpg_key"))
    #expect(scopes.contains("write:public_key"))
    #expect(q["state"] == "s1")
    // Workspace names the callback itself; a redirectUrl would only be ignored.
    #expect(q["redirectUrl"] == nil)
  }

  /// Workspace accepts a state of letters, digits, _ and - only, up to 100 characters.
  @Test func eachSignInSendsItsOwnStateWorkspaceAccepts() {
    let a = GitHubSignIn(), b = GitHubSignIn()
    #expect(a.state != b.state)
    #expect(a.state.count <= 100)
    #expect(a.state.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") })
  }

  @Test func theTokenComesBackWithThisSignInsState() {
    let link = URL(string: "keeta-agent://?token=gho_abc&state=s1")!
    #expect(signIn.outcome(of: link) == .signedIn(token: "gho_abc"))
  }

  /// A link this Mac didn't start (another sign-in's, or one someone else made) is ignored, so it
  /// can't put this Mac's keys on someone else's GitHub account.
  @Test func aLinkFromAnotherSignInIsIgnored() {
    #expect(signIn.outcome(of: URL(string: "keeta-agent://?token=gho_abc&state=other")!) == nil)
    #expect(signIn.outcome(of: URL(string: "keeta-agent://?token=gho_abc")!) == nil)
    #expect(signIn.outcome(of: URL(string: "keeta-agent://?error=access_denied")!) == nil)
  }

  /// agent.keeta.com put the token first and Signet read the first value as it; Workspace sends the
  /// reason instead when there is no token, and that is never taken for one.
  @Test func aRefusalSaysWhatHappened() {
    let denied = signIn.outcome(of: URL(string: "keeta-agent://?error=access_denied&state=s1")!)
    #expect(denied == .refused("You didn’t allow Signet on GitHub, so your keys weren’t added."))
    let failed = signIn.outcome(of: URL(string: "keeta-agent://?error=exchange_failed&state=s1")!)
    #expect(failed == .refused("GitHub couldn’t finish signing you in. Try again."))
    for reason in ["no_code", "something_new"] {
      let other = signIn.outcome(of: URL(string: "keeta-agent://?error=\(reason)&state=s1")!)
      #expect(other == .refused("Signing in to GitHub didn’t finish. Try again."))
    }
  }
}
