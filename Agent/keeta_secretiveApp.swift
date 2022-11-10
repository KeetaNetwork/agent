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
                .handlesExternalEvents(preferring: ["keeta-agent://"], allowing: ["*"])
                .onOpenURL { url in
                    guard let githubToken = url.description.GithubToken()?.value else { return }
//                    GithubAPI.pullUser(token: githubToken)
                }
            
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                EmptyView()
            }
        }
    }
}
