import SwiftUI

struct HeaderView: View {
    
    let user: GithubUser?
    let isReady: Bool
    let logout: () -> Void
    
    var body: some View {
        HStack {
            Text("Secure Enclave")
                .foregroundColor(KeetaColor.yellow)
                .font(.largeTitle)
            
            Spacer()
            
            if isReady {
                GithubButton(user: user, logout: logout)
            }
        }
    }
}

#if DEBUG
struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HeaderView(user: .init(username: "ty_schenk", avatarUrl: ""), isReady: false) {}
            HeaderView(user: .init(username: "ty_schenk", avatarUrl: ""), isReady: true) {}
        }
    }
}
#endif
