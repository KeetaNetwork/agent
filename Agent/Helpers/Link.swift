import Foundation

extension String {
    var githubToken: URLQueryItem? {
        guard let url = URL(string: self),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let tokenItem = components.queryItems?.first else { return nil }
        return tokenItem
    }
}
