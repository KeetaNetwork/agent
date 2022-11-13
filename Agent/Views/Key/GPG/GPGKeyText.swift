//
//  GPGKeyText.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct GPGKeyText: View {
    @ObservedObject var storage: Storage = .shared
    
    var body: some View {
        if let key = storage.user?.gpgKey {
            Text(key.key)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(KeetaColor.gray40)
            .multilineTextAlignment(.leading)
            .padding(EdgeInsets(top: AgentSpacing.zero, leading: AgentSpacing.large, bottom: AgentSpacing.large, trailing: AgentSpacing.large))
        }
    }
}

struct GPGKeyText_Previews: PreviewProvider {
    static var previews: some View {
        GPGKeyText()
    }
}
