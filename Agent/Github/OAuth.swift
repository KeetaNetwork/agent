//
//  OAuth.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import Foundation
import keeta_secure_storage
import KeychainSwift

class Storage: ObservableObject {

    let storage = SecureStorage(keychain: KeychainSwift())
    @Published private(set) var token: String?
    
    func storeToken(token: String) {
        try? storage.store(token, for: "keeta_agent_github")
        self.token = try? storage.object(for: "keeta_agent_github")
    }
}

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
    static func pullUser(token: String) async -> GithubUser? {
        guard let url = URL(string: "https://api.github.com/user") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        return try? await API().load(from: request)
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
