import SwiftUI

struct GithubButton: View {
    @Environment(\.openURL) var openURL
    @State private var showLogoutConfirmation = false
    
    let user: GithubUser?
    /// Starts a sign-in and gives the page to open.
    let signIn: () -> URL
    let logout: () -> Void
    
    var body: some View {
        Button(action: {
            if user == nil {
                openURL(signIn())
            } else {
                showLogoutConfirmation = true
            }
        }) {
            HStack(spacing: 0) {
                if let user = user {
                    AsyncImage(url: URL(string: user.avatarUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        KeetaColor.black
                    }
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.trailing, AgentSpacing.small)
                    Text(user.username)
                } else {
                    Image("github")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(.trailing, AgentSpacing.small)
                    Text("Sync with Github")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(KeetaColor.black)
            .foregroundColor(KeetaColor.yellow)
            .cornerRadius(25)
        }
        .buttonStyle(.plain)
        .alert("Do you want to disconnect your GitHub Account?", isPresented: $showLogoutConfirmation) {
            Button("Logout", action: logout)
            Button("Cancel", role: .cancel, action: {})
        }
    }
}

#if DEBUG
struct GithubButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GithubButton(user: nil, signIn: { URL(string: "https://example.com")! }) {}
            GithubButton(user: .preview, signIn: { URL(string: "https://example.com")! }) {}
        }
    }
}
#endif
