import Foundation

struct GithubUser: Codable {
    let username: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case username = "login"
        case avatarUrl = "avatar_url"
    }
}
