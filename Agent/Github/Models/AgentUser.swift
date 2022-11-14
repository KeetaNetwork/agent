//
//  AgentUser.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import Foundation

struct AgentUser: Codable {
    var token: String?
    var github: GithubUser?
    let gpgKey: GPGKey
    let sshKey: SSHKey
    
    enum CodingKeys: String, CodingKey {
        case token, github, gpgKey, sshKey
    }
}
