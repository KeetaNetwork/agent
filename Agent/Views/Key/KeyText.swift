//
//  KeyText.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct KeyText: View {
    var body: some View {
        Text("""
            -----BEGIN PGP PUBLIC KEY BLOCK-----
             TEST TEXT
            -----END PGP PUBLIC KEY BLOCK-----
        """)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(KeetaColor.gray40)
        .multilineTextAlignment(.leading)
        .padding(EdgeInsets(top: 0, leading: 24, bottom: 24, trailing: 24))
    }
}

struct KeyText_Previews: PreviewProvider {
    static var previews: some View {
        KeyText()
    }
}
