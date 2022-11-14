//
//  SSHKeyCopy.swift
//  Agent
//
//  Created by Ty Schenk on 11/12/22.
//

import SwiftUI

struct SSHKeyCopy: View {
    @ObservedObject var storage: Storage = .shared
    @State private var showingAlert = false
    @State private var copied = false
    
    var body: some View {
        Button {
            guard let key = storage.user?.sshKey else {
                showingAlert.toggle()
                return
            }
            
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(key.key, forType: .tabularText)
            copied.toggle()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
                copied.toggle()
            }
            
        } label: {
            HStack {
                Image("Copy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .opacity(copied ? 0 : 1)
                Text(copied ? "Copied!" : "Copy")
                    .font(.title3)
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(KeetaColor.red)
        .alert(isPresented: $showingAlert) { () -> Alert in
            Alert(title: Text("Agent Error"), message: Text("Failed to copy key to clipboard."), dismissButton: .default(Text("Ok")))
        }
    }
}

struct SSHKeyCopy_Previews: PreviewProvider {
    static var previews: some View {
        SSHKeyCopy()
    }
}

