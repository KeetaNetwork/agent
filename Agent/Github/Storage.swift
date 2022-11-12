//
//  Storage.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import Foundation
import keeta_secure_storage
import KeychainSwift

class Storage: ObservableObject {
    
    static let shared = Storage()
    
    let storage = SecureStorage(keychain: KeychainSwift())
    @Published private(set) var user: AgentUser?
    @Published private(set) var key: GPGKey?
    
    private init() {
        // attempt to load GPG key from storage
        if let key: GPGKey = try? storage.object(for: "keeta_agent_key") {
            self.key = key
        }
        
        // attempt to load user details from storage
        if let user: AgentUser = try? storage.object(for: "keeta_agent_user") {
            self.user = user
        }
    }
    
    func storeUser(user: AgentUser) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            try? self.storage.store(user, for: "keeta_agent_user")
            guard let user: AgentUser = try? storage.object(for: "keeta_agent_user") else { return }
            
            DispatchQueue.main.async {
                self.user = user
            }
        }
    }
    
    private func storeGPG(key: GPGKey) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            try? self.storage.store(key, for: "keeta_agent_key")
            guard let key: GPGKey = try? storage.object(for: "keeta_agent_key") else { return }
            
            DispatchQueue.main.async {
                self.key = key
            }
        }
    }
    
    func generateKey(name: String, email: String) {
        let TEMP_KEY = "TEST KEY ONLY"
        let user = GPGUser(name: name, email: email)
        let key = GPGKey(key: TEMP_KEY, user: user)
        storeGPG(key: key)
    }
}
