//
//  KeyView.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct KeyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            KeyHeader()
            KeyDivider()
            KeyText()
        }
        .background(KeetaColor.black)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KeetaColor.gray50, lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

struct KeyView_Previews: PreviewProvider {
    static var previews: some View {
        KeyView()
    }
}
