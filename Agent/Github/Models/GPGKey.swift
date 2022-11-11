//
//  GPGKey.swift
//  Agent
//
//  Created by Ty Schenk on 11/10/22.
//

import Foundation

typealias Key = String

struct GPGUser: Codable {
    let name: String
    let email: String
}

struct GPGKey: Codable {
    let key: Key
    let user: GPGUser
}
