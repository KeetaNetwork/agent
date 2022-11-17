//
//  GithubSSH.swift
//  Agent
//
//  Created by Ty Schenk on 11/12/22.
//

import Foundation

struct GithubSSH: Codable {
    let id: Int
    let title: String
    let key: String
    let verified: Bool
    let readOnly: Bool
    
    enum CodingKeys: String, CodingKey {
        case id,
             title,
             key,
             verified,
             readOnly = "read_only"
    }
}
