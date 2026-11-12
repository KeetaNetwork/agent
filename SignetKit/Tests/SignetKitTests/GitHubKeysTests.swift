// Putting the device's keys on the person's GitHub account (signet-update-brief.md step 5): GitHub
// verifies SSH-signed commits only against an account's signing keys, a list apart from its
// authentication keys, so Signet adds the key to both.
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import Foundation
import SignetKit
import Testing

/// Answers requests the way GitHub's API would, and keeps what was asked.
final class FakeGitHub: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var answers: [String: (Int, String)] = [:]
  nonisolated(unsafe) static var asked: [(method: String, path: String, auth: String?, body: [String: Any])] = []

  override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "api.github.com" }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    var body = Data()
    if let d = request.httpBody { body = d }
    if let s = request.httpBodyStream {
      s.open()
      var buf = [UInt8](repeating: 0, count: 4096)
      while s.hasBytesAvailable { let n = s.read(&buf, maxLength: buf.count); if n <= 0 { break }; body.append(buf, count: n) }
      s.close()
    }
    let path = request.url!.path
    Self.asked.append((request.httpMethod ?? "GET", path, request.value(forHTTPHeaderField: "Authorization"),
                       (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] ?? [:]))
    let (status, json) = Self.answers[path] ?? (404, #"{"message":"Not Found"}"#)
    client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Data(json.utf8))
    client?.urlProtocolDidFinishLoading(self)
  }
  override func stopLoading() {}

  static func session() -> URLSession {
    let c = URLSessionConfiguration.ephemeral
    c.protocolClasses = [FakeGitHub.self]
    return URLSession(configuration: c)
  }
}

@Suite(.serialized) struct GitHubKeysTests {
  init() {
    FakeGitHub.asked = []
    FakeGitHub.answers = [:]
  }

  @Test func theKeyIsAddedAsASigningKeyAndForSSH() async throws {
    FakeGitHub.answers["/user/ssh_signing_keys"] = (201, #"{"id":1,"key":"ecdsa-sha2-nistp256 AAAA","title":"Signet"}"#)
    FakeGitHub.answers["/user/keys"] = (201, #"{"id":2,"key":"ecdsa-sha2-nistp256 AAAA","title":"Signet"}"#)
    let gh = GitHubKeys(token: "gho_test", session: FakeGitHub.session())
    try await gh.addSSHKey("ecdsa-sha2-nistp256 AAAA", title: "Signet MacBook")

    let paths = FakeGitHub.asked.map { "\($0.method) \($0.path)" }.sorted()
    #expect(paths == ["POST /user/keys", "POST /user/ssh_signing_keys"])
    for a in FakeGitHub.asked {
      #expect(a.auth == "Bearer gho_test")
      #expect(a.body["key"] as? String == "ecdsa-sha2-nistp256 AAAA")
      #expect(a.body["title"] as? String == "Signet MacBook")
    }
  }

  /// A key GitHub already has (422, "key is already in use") is where it should be.
  @Test func aKeyGitHubAlreadyHasIsNotAFailure() async throws {
    let taken = #"{"message":"Validation Failed","errors":[{"resource":"PublicKey","code":"custom","field":"key","message":"key is already in use"}]}"#
    FakeGitHub.answers["/user/ssh_signing_keys"] = (422, taken)
    FakeGitHub.answers["/user/keys"] = (422, taken)
    try await GitHubKeys(token: "t", session: FakeGitHub.session()).addSSHKey("ecdsa-sha2-nistp256 AAAA", title: "Signet")
  }

  @Test func otherFailuresSayWhatGitHubAnswered() async throws {
    FakeGitHub.answers["/user/ssh_signing_keys"] = (403, #"{"message":"You need write:ssh_signing_key"}"#)
    FakeGitHub.answers["/user/keys"] = (201, #"{"id":2}"#)
    await #expect(throws: GitHubKeys.Failure.self) {
      try await GitHubKeys(token: "t", session: FakeGitHub.session()).addSSHKey("ecdsa-sha2-nistp256 AAAA", title: "Signet")
    }
  }

  @Test func signingInAsksForTheSigningKeyScope() {
    let query = URLComponents(url: GitHubKeys.signInURL, resolvingAgainstBaseURL: false)!.queryItems!
    let scopes = query.first { $0.name == "scopes" }!.value!.split(separator: ",")
    #expect(scopes.contains("write:ssh_signing_key"))
    #expect(scopes.contains("write:gpg_key"))
  }
}
