//
//  KeyView.swift
//  Agent
//
//  Created by Ty Schenk on 11/8/22.
//

import SwiftUI

struct KeyView: View {
    @ObservedObject var storage: Storage = .shared
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showingAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let _ = storage.key {
                KeyHeader()
                KeyDivider()
                KeyText()
            } else {
                VStack(alignment: .leading, spacing: AgentSpacing.large) {
                    VStack(alignment: .leading, spacing: AgentSpacing.small) {
                        Text("Generate your GPG Key")
                            .foregroundColor(KeetaColor.yellow)
                            .font(.title)
                        Text("Please enter the following information, which will be associated with your GPG key.")
                            .font(.subheadline)
                            .foregroundColor(KeetaColor.gray40)
                    }
                    VStack(alignment: .leading, spacing: AgentSpacing.medium) {
                        Text("Full Name")
                        TextField("", text: $name)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(KeetaColor.yellow, lineWidth: 1)
                            )
                        Text("Email")
                        TextField("", text: $email)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(KeetaColor.yellow, lineWidth: 1)
                            )
                    }
                    Button {
                        if !name.isEmpty && !email.isEmpty && isValidEmail(email) {
                            storage.generateKey(name: name, email: email)
                        } else {
                            showingAlert = true
                        }
                    } label: {
                        Text("Generate GPG Key")
                            .foregroundColor(KeetaColor.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                    }
                    .alert(isPresented: $showingAlert) { () -> Alert in
                        Alert(title: Text("Agent Error"), message: name.isEmpty ? Text("Please enter a name.") : Text("Please enter a valid email."), dismissButton: .default(Text("Ok")))
                    }
                    .buttonStyle(.plain)
                    .background(KeetaColor.red)
                    .cornerRadius(40)
                }
                .padding(EdgeInsets(top: AgentSpacing.large, leading: AgentSpacing.large, bottom: AgentSpacing.large, trailing: AgentSpacing.large))
            }
        }
        .background(KeetaColor.black)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KeetaColor.gray50, lineWidth: 1)
        )
        .cornerRadius(16)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct KeyView_Previews: PreviewProvider {
    static var previews: some View {
        KeyView()
    }
}
