import SwiftUI

struct GithubButton: View {
    @Environment(\.openURL) var openURL
    
    let user: GithubUser?
    
    var body: some View {
        Button(action: {
            if user == nil {
                openURL(GithubAPI.githubButtonUrl)
            }
        }) {
            HStack {
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
            .padding(20)
            .background(KeetaColor.black)
            .foregroundColor(KeetaColor.yellow)
            .cornerRadius(25)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
struct GithubButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GithubButton(user: nil)
            GithubButton(user: .init(username: "ty_schenk", avatarUrl: ""))
        }
    }
}
#endif
