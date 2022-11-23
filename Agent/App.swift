import SwiftUI

@main
struct KeetaAgentApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        Dependencies.all.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
                .handlesExternalEvents(preferring: ["keeta-agent"], allowing: ["keeta-agent"])
                .onOpenURL(perform: appDelegate.handle(url:))
        }
        .commands { CommandGroup(replacing: .newItem, addition: { }) }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
}
