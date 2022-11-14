//
//  SSHKeyIcon.swift
//  Agent
//
//  Created by Ty Schenk on 11/12/22.
//

import SwiftUI

struct SSHKeyIcon: View {
    var body: some View {
        HStack {
            Image("Key")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text("SSH Key")
                .foregroundColor(KeetaColor.yellow)
                .font(.title3)
        }
    }
}

struct SSHKeyIcon_Previews: PreviewProvider {
    static var previews: some View {
        SSHKeyIcon()
    }
}
