//
//  GithubButton.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI
import Combine

struct GithubButton: View {
    @Environment(\.openURL) var openURL
    @ObservedObject var storage: Storage = .shared
    
    var body: some View {
        if let user = storage.user {
            HStack {
                AsyncImage(url: URL(string: user.github.avatarUrl)) { image in
                    image.resizable()
                } placeholder: {
                    KeetaColor.black
                }
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                Text(user.github.username)
            }.padding(8)
            .background(KeetaColor.black)
            .foregroundColor(KeetaColor.yellow)
            .cornerRadius(18)
        } else {
            Button {
                guard let githubUrl = URL(string: "https://agent.keeta.com/api/github/oauth/login?scopes=write:gpg_key&redirectUrl=https://agent.keeta.com/api/github/oauth/callback") else { return }
                openURL(githubUrl)
            } label: {
                HStack {
                    Image("github")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                    Text(verbatim: "Connect with Github")
                }
            }
            .padding(8)
            .buttonStyle(.plain)
            .background(KeetaColor.black)
            .foregroundColor(KeetaColor.yellow)
            .cornerRadius(18)
        }
    }
}

struct GithubButton_Previews: PreviewProvider {
    static var previews: some View {
        GithubButton()
    }
}
