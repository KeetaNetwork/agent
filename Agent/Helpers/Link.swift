//
//  Link.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import Foundation

//keeta-agent://token=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

extension String {
    func GithubToken() -> URLQueryItem? {
        guard let url = URL(string: self),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let tokenItem = components.queryItems?.first else { return nil }
        return tokenItem
    }
}
