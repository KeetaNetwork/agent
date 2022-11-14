import SwiftUI

@main
struct keeta_secretiveApp: App {
    
    init() {
        Dependencies.all.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .handlesExternalEvents(preferring: ["keeta-agent"], allowing: ["keeta-agent"])
                .onOpenURL { url in
                    Task {
                        guard let githubToken = url.description.GithubToken()?.value,
                              let user = await GithubAPI.pullUser(token: githubToken) else { return }
                        Storage.shared.storeGithubUser(user: user, token: githubToken)
                    }
                }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
}
