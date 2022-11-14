//
//  SSHKeyHeader.swift
//  Agent
//
//  Created by Ty Schenk on 11/12/22.
//

import SwiftUI

struct SSHKeyHeader: View {
    var body: some View {
        HStack {
            SSHKeyIcon()
            Spacer()
            SSHKeyCopy()
        }
        .padding(EdgeInsets(top: AgentSpacing.large, leading: AgentSpacing.large, bottom: AgentSpacing.large, trailing: AgentSpacing.large))
    }
}

struct SSHKeyHeader_Previews: PreviewProvider {
    static var previews: some View {
        SSHKeyHeader()
    }
}
