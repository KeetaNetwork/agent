//
//  keeta_secretiveApp.swift
//  keeta-secretive
//
//  Created by David Scheutz on 11/3/22.
//

import SwiftUI

@main
struct keeta_secretiveApp: App {
    
    init() {
        Dependencies.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .handlesExternalEvents(preferring: ["keeta-agent"], allowing: ["keeta-agent"])
                .onOpenURL { url in
                    Task {
                        guard let githubToken = url.description.GithubToken()?.value,
                              let user = await GithubAPI.pullUser(token: githubToken) else { return }
                        let agentUser = AgentUser(token: githubToken, github: user)
                        Storage.shared.storeUser(user: agentUser)
                    }
                }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
}
