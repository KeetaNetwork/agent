import SwiftUI

struct HeaderView: View {
    
    let user: GithubUser?
    let isReady: Bool
    let signIn: () -> URL
    let logout: () -> Void
    
    var body: some View {
        HStack {
            Text("Signet")
                .foregroundColor(KeetaColor.yellow)
                .font(.largeTitle)
            
            Spacer()
            
            if isReady {
                GithubButton(user: user, signIn: signIn, logout: logout)
            }
        }
    }
}

#if DEBUG
struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HeaderView(user: .preview, isReady: false, signIn: { URL(string: "https://example.com")! }) {}
            HeaderView(user: .preview, isReady: true, signIn: { URL(string: "https://example.com")! }) {}
        }
    }
}
#endif
