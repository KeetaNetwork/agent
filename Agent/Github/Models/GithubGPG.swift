//
//  GithubGPG.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import Foundation

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
