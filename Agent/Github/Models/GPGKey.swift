//
//  GPGKey.swift
//  Agent
//
//  Created by Ty Schenk on 11/10/22.
//

import Foundation

struct GPGUser: Codable {
    let name: String
    let email: String
}

struct GPGKey: Codable {
    let key: String
    let user: GPGUser
}
