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
        if let _ = storage.user {
            Button {
                if storage.user?.github == nil {
                    openURL(GithubAPI.githubButtonUrl)
                }
            } label: {
                HStack {
                    if let user = storage.user?.github {
                        AsyncImage(url: URL(string: user.avatarUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            KeetaColor.black
                        }
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(EdgeInsets(top: AgentSpacing.zero, leading: AgentSpacing.zero, bottom: AgentSpacing.zero, trailing: AgentSpacing.small))
                        Text(user.username)
                    } else {
                        Image("github")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(EdgeInsets(top: AgentSpacing.zero, leading: AgentSpacing.zero, bottom: AgentSpacing.zero, trailing: AgentSpacing.small))
                        Text("Sync with Github")
                    }
                }
            }.padding(20)
                .buttonStyle(.plain)
                .background(KeetaColor.black)
                .foregroundColor(KeetaColor.yellow)
                .cornerRadius(25)
        }
    }
}

struct GithubButton_Previews: PreviewProvider {
    static var previews: some View {
        GithubButton()
    }
}
