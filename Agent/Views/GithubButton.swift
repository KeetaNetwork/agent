//
//  GithubButton.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct GithubButton: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button {
            guard let githubUrl = URL(string: "https://agent.keeta.com/api/github/oauth/login?scopes=write:gpg_key&redirectUrl=https://agent.keeta.com/api/github/oauth/callback") else { return }
            openURL(githubUrl)
        } label: {
            HStack {
                Image("github")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(verbatim: "Connect with Github")
            }
        }
        .frame(width: 226, height: 56)
        .buttonStyle(.plain)
        .background(KeetaColor.black)
        .foregroundColor(KeetaColor.yellow)
        .cornerRadius(40)
    }
}

struct GithubButton_Previews: PreviewProvider {
    static var previews: some View {
        GithubButton()
    }
}
