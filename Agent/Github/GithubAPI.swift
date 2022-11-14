import Foundation

private final class API {
    var session = URLSession.shared
    let decoder = JSONDecoder()

    func load<T: Decodable>(from request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { throw NSError(domain: "Invalid response", code: 500) }
        guard statusCode == 200 else { throw NSError(domain: "Invalid HTTP status code", code: statusCode) }
        return try decoder.decode(T.self, from: data)
    }
}

final class GithubAPI {
        
    private let token: String
    private let api = API()
    
    init(token: String) {
        self.token = token
    }
    
    static let githubButtonUrl = URL(string: "https://agent.keeta.com/api/github/oauth/login?scopes=write:public_key,write:gpg_key&redirectUrl=https://agent.keeta.com/api/github/oauth/callback")!
    
    func pullUser() async -> GithubUser? {
        guard let url = URL(string: "https://api.github.com/user") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        return try? await api.load(from: request)
    }
    
    func uploadGPG(key: String) async throws {
        guard let url = URL(string: "https://api.github.com/user/gpg_keys") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let json: [String: Any] = [
            "name": "Keeta Agent",
            "armored_public_key": key
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let resultData: GithubGPG = try await api.load(from: request)
        debugPrint(resultData)
    }
    
    func uploadSSH(key: String) async throws {
        guard let url = URL(string: "https://api.github.com/user/keys") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let json: [String: Any] = [
            "title": "Keeta Agent",
            "key": key
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let resultData: GithubSSH = try await api.load(from: request)
        debugPrint(resultData)
    }
}
