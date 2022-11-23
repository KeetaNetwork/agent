import SwiftUI

struct GithubButton: View {
    @Environment(\.openURL) var openURL
    @State private var showLogoutConfirmation = false
    
    let user: GithubUser?
    let logout: () -> Void
    
    var body: some View {
        Button(action: {
            if user == nil {
                openURL(GithubAPI.githubButtonUrl)
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
            GithubButton(user: nil) {}
            GithubButton(user: .preview) {}
        }
    }
}
#endif
