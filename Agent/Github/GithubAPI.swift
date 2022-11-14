//
//  GithubAPI.swift
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

struct GithubAPI {
    
    private let storage = Storage.shared
    
    static let githubButtonUrl = URL(string: "https://agent.keeta.com/api/github/oauth/login?scopes=write:public_key,write:gpg_key&redirectUrl=https://agent.keeta.com/api/github/oauth/callback")!
    
    static func pullUser(token: String) async -> GithubUser? {
        guard let url = URL(string: "https://api.github.com/user") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        return try? await API().load(from: request)
    }
    
    static func uploadGPG(key: String) async throws {
        guard let url = URL(string: "https://api.github.com/user/gpg_keys") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(Storage.shared.user?.token ?? "")", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let json: [String: Any] = [
            "name": "Keeta Agent",
            "armored_public_key": key
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let resultData: GithubGPG = try await API().load(from: request)
        debugPrint(resultData)
    }
    
    static func uploadSSH(key: String) async throws {
        guard let url = URL(string: "https://api.github.com/user/keys") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(Storage.shared.user?.token ?? "")", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let json: [String: Any] = [
            "title": "Keeta Agent",
            "key": key
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let resultData: GithubSSH = try await API().load(from: request)
        debugPrint(resultData)
    }
}
