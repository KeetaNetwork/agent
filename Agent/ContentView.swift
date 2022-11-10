//
//  ContentView.swift
//  keeta-secretive
//
//  Created by David Scheutz on 11/3/22.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(alignment: .leading) {
            HeaderView()
            KeyView()
            Spacer()
            KeetaButton()
        }
        .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        .background(KeetaColor.gray)
        .frame(width: 600, height: 544)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
