//
//  GPGKeyHeader.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct GPGKeyHeader: View {
    var body: some View {
        HStack {
            GPGKeyIcon()
            Spacer()
            GPGKeyCopy()
        }
        .padding(EdgeInsets(top: AgentSpacing.large, leading: AgentSpacing.large, bottom: AgentSpacing.large, trailing: AgentSpacing.large))
    }
}

struct GPGKeyHeader_Previews: PreviewProvider {
    static var previews: some View {
        GPGKeyHeader()
    }
}
