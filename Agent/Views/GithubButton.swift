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
        Button {
            if storage.user == nil {
                guard let githubUrl = URL(string: "https://agent.keeta.com/api/github/oauth/login?scopes=write:gpg_key&redirectUrl=https://agent.keeta.com/api/github/oauth/callback") else { return }
                openURL(githubUrl)
            }
        } label: {
            HStack {
                if let user = storage.user {
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
                } else {
                    Image("github")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                    Text("Connect with Github")
                }
            }
        }.padding(10)
            .buttonStyle(.plain)
            .background(KeetaColor.black)
            .foregroundColor(KeetaColor.yellow)
            .cornerRadius(18)
    }
}

struct GithubButton_Previews: PreviewProvider {
    static var previews: some View {
        GithubButton()
    }
}
