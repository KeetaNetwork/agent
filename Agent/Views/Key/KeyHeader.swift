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
        .padding(EdgeInsets(top: 24.0, leading: 24.0, bottom: 24.0, trailing: 24.0))
    }
}

struct KeyHeader_Previews: PreviewProvider {
    static var previews: some View {
        KeyHeader()
    }
}
