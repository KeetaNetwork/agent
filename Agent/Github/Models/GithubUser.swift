//
//  GithubUser.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import Foundation

struct GithubUser: Codable {
    let username: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case username = "login",
             avatarUrl = "avatar_url"
    }
}
