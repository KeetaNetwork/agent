//
//  AgentUser.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import Foundation

struct AgentUser: Codable {
    let token: String
    let github: GithubUser
    
    enum CodingKeys: String, CodingKey {
        case token, github
    }
}
