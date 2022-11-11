//
//  KeyHeader.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct KeyHeader: View {
    var body: some View {
        HStack {
            KeyIcon()
            Spacer()
            KeyCopy()
        }
        .padding(EdgeInsets(top: AgentSpacing.large, leading: AgentSpacing.large, bottom: AgentSpacing.large, trailing: AgentSpacing.large))
    }
}

struct KeyHeader_Previews: PreviewProvider {
    static var previews: some View {
        KeyHeader()
    }
}
