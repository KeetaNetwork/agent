//
//  OAuth.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import Foundation

class API {
    var session = URLSession.shared
    let decoder = JSONDecoder()

    func load<T: Decodable>(from request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { throw NSError(domain: "Invalid response", code: 500) }
        guard statusCode == 200 else { throw NSError(domain: "Invalid HTTP status code", code: statusCode) }
        return try decoder.decode(T.self, from: data)
    }
}

struct GithubToken: Codable {
    let token: String
}

struct GithubUser: Codable {
    let username: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case username = "login"
        case avatarUrl = "avatar_url"
    }
}

struct Email: Codable {
    let email: String
    let verified: Bool
}

struct GithubGPG: Codable {
    let id: String
    let name: String
    let primaryKeyId: Int
    let keyId: String
    let publicKey: String
    let emails: [Email]
    let canSign: Bool
    let canCertify: Bool
    let revoked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id,
             name,
             primaryKeyId = "primary_key_id",
             keyId = "key_id",
             publicKey = "public_key",
             emails,
             canSign = "can_sign",
             canCertify = "can_certify",
             revoked
    }
}

struct GithubAPI {
    static func pullUser(token: String) {
        Task {
            guard let url = URL(string: "https://api.github.com/user") else { return }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            
            let res: GithubUser = try await API().load(from: request)
            print(res)
        }
    }
    
    static func uploadGPG(token: String, key: String) {
        Task {
            guard let url = URL(string: "https://api.github.com/user/gpg_keys") else { return }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            
            let json: [String: Any] = [
                "name": "Keeta Agent",
                "armored_public_key": key
            ]
            
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            
            let res: GithubGPG = try await API().load(from: request)
            print(res)
        }
        
    }
}

// https://agent.keeta.com/api/github/oauth/login?scopes=write:gpg_key&redirectUrl=https://agent.keeta.com/api/github/oauth/callback

// {"token":"gho_2OpmcGjbbG55DTQrKtZaD4l8uKD4"}

// -H "Authorization: Bearer <YOUR-TOKEN>" \

// GET https://api.github.com/user

//{
//    "login": "schenkty",
//    "id": 7807169,
//    "node_id": "MDQ6VXNlcjc4MDcxNjk=",
//    "avatar_url": "https://avatars.githubusercontent.com/u/7807169?v=4",
//    "gravatar_id": "",
//    "url": "https://api.github.com/users/schenkty",
//    "html_url": "https://github.com/schenkty",
//    "followers_url": "https://api.github.com/users/schenkty/followers",
//    "following_url": "https://api.github.com/users/schenkty/following{/other_user}",
//    "gists_url": "https://api.github.com/users/schenkty/gists{/gist_id}",
//    "starred_url": "https://api.github.com/users/schenkty/starred{/owner}{/repo}",
//    "subscriptions_url": "https://api.github.com/users/schenkty/subscriptions",
//    "organizations_url": "https://api.github.com/users/schenkty/orgs",
//    "repos_url": "https://api.github.com/users/schenkty/repos",
//    "events_url": "https://api.github.com/users/schenkty/events{/privacy}",
//    "received_events_url": "https://api.github.com/users/schenkty/received_events",
//    "type": "User",
//    "site_admin": false,
//    "name": "Ty Schenk",
//    "company": "@KeetaPay",
//    "blog": "https://keeta.com",
//    "location": "Los Angeles, CA",
//    "email": null,
//    "hireable": null,
//    "bio": "CEO @KeetaPay,\r\npreviously @turo, @brainblocks ",
//    "twitter_username": "schenkty",
//    "public_repos": 47,
//    "public_gists": 2,
//    "followers": 23,
//    "following": 23,
//    "created_at": "2014-06-05T15:53:48Z",
//    "updated_at": "2022-11-08T07:16:09Z"
//}
