//
//  HeaderView.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct HeaderView: View {
    
    var body: some View {
        HStack {
            Text("Secure Enclave")
                .foregroundColor(KeetaColor.yellow)
                .font(.largeTitle)
            Spacer()
            GithubButton()
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
    }
}
