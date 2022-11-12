//
//  KeyDivider.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct KeyDivider: View {
    var body: some View {
        Spacer()
            .frame(width: 552, height: 1)
            .background(KeetaColor.gray50)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: AgentSpacing.large, trailing: 0))
    }
}

struct KeyDivider_Previews: PreviewProvider {
    static var previews: some View {
        KeyDivider()
    }
}
