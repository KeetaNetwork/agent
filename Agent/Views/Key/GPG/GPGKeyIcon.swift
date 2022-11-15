//
//  GPGKeyIcon.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct GPGKeyIcon: View {
    let uploaded: Bool
    
    var body: some View {
        HStack {
            Image("Key")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text("GPG Key")
                .foregroundColor(KeetaColor.yellow)
                .font(.title3)
            
            if uploaded {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(KeetaColor.green)
                    .help(Text("Uploaded to Github"))
            }
        }
    }
}

struct GPGKeyIcon_Previews: PreviewProvider {
    static var previews: some View {
        GPGKeyIcon(uploaded: true)
    }
}
