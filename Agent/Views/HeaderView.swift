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
            HeaderView(user: .preview, isReady: false) {}
            HeaderView(user: .preview, isReady: true) {}
        }
    }
}
#endif
