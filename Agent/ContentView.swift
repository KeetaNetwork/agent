import Foundation
import SwiftUI

struct ContentView: View {
    @ObservedObject var keetaAgent: KeetaAgent = Dependencies.all.keetaAgent
    
    var body: some View {
        VStack(alignment: .leading) {
            let isReady = keetaAgent.gpgKey != nil && keetaAgent.sshKey != nil
            HeaderView(user: keetaAgent.githubUser, isReady: isReady)
                .padding(.bottom, AgentSpacing.large)
            
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
        .frame(width: 620, height: 700)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
