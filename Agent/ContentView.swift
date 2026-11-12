import Foundation
import SignetKit
import SwiftUI

struct ContentView: View {
    
    @ObservedObject var keetaAgent: KeetaAgent = Dependencies.all.keetaAgent
    
    var body: some View {
        VStack(alignment: .leading) {
            let isReady = keetaAgent.gpgKey != nil && keetaAgent.sshKey != nil
            
            HeaderView(user: keetaAgent.githubUser, isReady: isReady, signIn: keetaAgent.startGitHubSignIn, logout: keetaAgent.logout)
                .padding(.bottom, AgentSpacing.large)
            
            if keetaAgent.socketState == .standingBy {
                Text("Served by Workspace for Mac. Signet takes over if it quits.")
                    .font(.callout)
                    .foregroundColor(KeetaColor.gray40)
                    .padding(.bottom, AgentSpacing.medium)
            }
            
            if let gpgKey = keetaAgent.gpgKey, let sshKey = keetaAgent.sshKey {
                KeyView(gpgKey: gpgKey, sshKey: sshKey)
            } else {
                GenerateView()
            }
            
            Spacer()
            
            KeetaButton()
        }
        .padding(AgentSpacing.large)
        .background(KeetaColor.gray)
        .frame(width: 400)
        .alert(
            "GitHub isn’t connected",
            isPresented: Binding(get: { keetaAgent.githubRefusal != nil }, set: { if !$0 { keetaAgent.githubRefusal = nil } }),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(keetaAgent.githubRefusal ?? "") }
        )
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
