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
    
    private init() {
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
}
