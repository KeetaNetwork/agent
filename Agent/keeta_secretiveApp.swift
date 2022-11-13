import SwiftUI

@main
struct keeta_secretiveApp: App {
    
    init() {
        Dependencies.all.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .handlesExternalEvents(preferring: ["keeta-agent://"], allowing: ["*"])
                .onOpenURL { url in
                    Task {
                        guard let githubToken = url.description.GithubToken()?.value,
                              let user = await GithubAPI.pullUser(token: githubToken) else { return }
                        let agentUser = AgentUser(token: githubToken, github: user)
                        Storage.shared.storeUser(user: agentUser)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                EmptyView()
            }
        }
    }
}
