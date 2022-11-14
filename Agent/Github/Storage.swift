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
        // attempt to load user details from storage
        if let user: AgentUser = try? storage.object(for: "keeta_agent_user") {
            self.user = user
        }
    }
    
    private func storeUser(user: AgentUser) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            try? self.storage.store(user, for: "keeta_agent_user")
            guard let user: AgentUser = try? storage.object(for: "keeta_agent_user") else { return }
            
            DispatchQueue.main.async {
                self.user = user
            }
        }
    }
    
    func storeGithubUser(user: GithubUser, token: String) {
        guard let currentUser = self.user else { return }
        let updatedUser = AgentUser(token: token, github: user, gpgKey: currentUser.gpgKey, sshKey: currentUser.sshKey)
        storeUser(user: updatedUser)
    }
    
    func generateKeys(name: String, email: String) {
        let TEMP_KEY = "TEST KEY ONLY"
        let user = GPGUser(name: name, email: email)
        let gpgKey = GPGKey(key: TEMP_KEY, user: user)
        let sshKey = SSHKey(key: TEMP_KEY)
        let agentUser = AgentUser(gpgKey: gpgKey, sshKey: sshKey)
        
//        Task {
//            try await GithubAPI.uploadGPG(key: gpgKey)
//            try await GithubAPI.uploadSSH(key: sshKey)
//        }
        
        storeUser(user: agentUser)
    }
}
