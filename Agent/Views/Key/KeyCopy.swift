//
//  KeyCopy.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct KeyCopy: View {
    var body: some View {
        Button {

        } label: {
            HStack {
                Image("Copy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Copy")
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(KeetaColor.red)
    }
}

struct KeyCopy_Previews: PreviewProvider {
    static var previews: some View {
        KeyCopy()
    }
}
