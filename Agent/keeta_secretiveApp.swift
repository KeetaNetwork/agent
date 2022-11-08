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
                    guard let token = url.description.GithubToken()?.value else { return }
                    GithubAPI.pullUser(token: token)
                }
            
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                EmptyView()
            }
        }
    }
}
