//
//  KeyIcon.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct KeyIcon: View {
    var body: some View {
        HStack {
            Image("Key")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text("GPG Key")
                .foregroundColor(KeetaColor.yellow)
                .font(.title3)
        }
    }
}

struct KeyIcon_Previews: PreviewProvider {
    static var previews: some View {
        KeyIcon()
    }
}
