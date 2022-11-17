//
//  KeetaButton.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct KeetaButton: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button {
            guard let keetaUrl = URL(string: "https://keeta.com") else { return }
            openURL(keetaUrl)
        } label: {
            Image("Powered")
                .resizable()
                .scaledToFit()
                .frame(width: 113, height: 24)
        }
        .buttonStyle(.plain)
        .padding(.top, AgentSpacing.large)
    }
}

struct KeetaButton_Previews: PreviewProvider {
    static var previews: some View {
        KeetaButton()
    }
}
