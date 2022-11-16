import SwiftUI

@main
struct KeetaAgentApp: App {
    
    init() {
        Dependencies.all.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .handlesExternalEvents(preferring: ["keeta-agent"], allowing: ["keeta-agent"])
                .onOpenURL(perform: Dependencies.all.keetaAgent.didReceive(url:))
                .onAppear { NSWindow.allowsAutomaticWindowTabbing = false }
        }
        .commands { CommandGroup(replacing: .newItem, addition: { }) }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
}
