import Foundation

final class GithubAPI {
        
    private let token: String
    private let api = API()
    private let keyTitle = "Keeta Agent " + (serialNumber() ?? "Unknown Device")
    private let baseUrl = "https://api.github.com"
    
    init(token: String) {
        self.token = token
    }
    
    static let githubButtonUrl = URL(string: "https://agent.keeta.com/api/github/oauth/login?scopes=user,write:public_key,write:gpg_key&redirectUrl=https://agent.keeta.com/api/github/oauth/callback"
    )!
    
    func pullUser() async -> GithubUser? {
        guard let url = URL(string: baseUrl + "/user") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        return try? await api.load(from: request).success()
    }
    
    func uploadGPG(key: String) async throws {
        guard let url = URL(string: baseUrl + "/user/gpg_keys") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let json: [String: Any] = [
            "name": keyTitle,
            "armored_public_key": key
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let _: GithubGPG = try await api.load(from: request).success()
    }
    
    func uploadSSH(key: String) async throws {
        guard let url = URL(string: baseUrl + "/user/keys") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let json: [String: Any] = [
            "title": keyTitle,
            "key": key
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let _: GithubSSH = try await api.load(from: request).success()
    }
    
    func uploadEmail(_ email: String) async throws {
        guard let url = URL(string: baseUrl + "/user/emails") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let json: [String: Any] = [
            "emails": [email]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let _: [GithubEmail] = try await api.load(from: request).success()
    }
}

private final class API {
    var session = URLSession.shared
    let decoder = JSONDecoder()

    enum Result<T: Decodable> {
        case success(T)
        case error(GithubErrorResponse)
        
        func success() throws -> T {
            switch self {
            case .success(let success):
                return success
            case .error(let error):
                throw NSError(domain: "Result contains an error: \(error)", code: 500)
            }
        }
    }
    
    func load<T: Decodable>(from request: URLRequest) async throws -> Result<T> {
        let (data, response) = try await session.data(for: request)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { throw NSError(domain: "Invalid response", code: 500) }
        guard (200..<300).contains(statusCode) else {
            return .error(try decoder.decode(GithubErrorResponse.self, from: data))
        }
        return .success(try decoder.decode(T.self, from: data))
    }
}

private struct GithubErrorResponse: Decodable {
    let message: String
    let errors: [GithubError]
}

private struct GithubError: Decodable {
    let resource: String
    let field: String
    let code: String
}
