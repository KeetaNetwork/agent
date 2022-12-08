import Foundation

struct GithubEmail: Decodable {
    let email: String
    let primary: Bool
    let verified: Bool
    let visibility: String
}
