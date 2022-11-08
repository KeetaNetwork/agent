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
            HStack {
                Text("Dashboard")
                    .foregroundColor(KeetaColor.yellow)
                    .font(.title)
                Spacer()
                Button {
                    guard let githubUrl = URL(string: "https://agent.keeta.com/api/github/oauth/login?scopes=write:gpg_key&redirectUrl=https://agent.keeta.com/api/github/oauth/callback") else { return }
                    openURL(githubUrl)
                } label: {
                    HStack {
                        Image("github")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text(verbatim: "Connect with Github")
                    }
                }
                .frame(width: 226, height: 56)
                .buttonStyle(.plain)
                .background(KeetaColor.black)
                .foregroundColor(KeetaColor.yellow)
                .cornerRadius(40)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack {
                        Image("Key")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text("GPG Key")
                            .foregroundColor(KeetaColor.yellow)
                    }
                    Spacer()
                    HStack {
                        Button {
                            
                        } label: {
                            HStack {
                                Image("Copy")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text(verbatim: "Copy")
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(KeetaColor.red)
                    }
                }
                .padding(EdgeInsets(top: 24.0, leading: 24.0, bottom: 24.0, trailing: 24.0))
                Spacer()
                    .frame(width: 552, height: 1)
                    .background(KeetaColor.gray)
                Text("""
                    -----BEGIN PGP PUBLIC KEY BLOCK-----
                     mFIEY2nI9BMIKoZIzj0DAQcCAwTxpDGIWjacNeBe
                     vclHJNIvgOaUZ7+ioWivxTLa 5zIyBfxb4NOkyay3ouaV
                     Cl8HoUcC4OHXLjiy/1itEkPoMfwtBxSb3kgS2VlbmUg
                     PHJrZWVuZUBrZWV0YS5jb20+iJMEExMIADsWIQQ
                     gr6QNn6PTC6UWD7YDSS4BiK3SuQUCY2nI9AIbAw
                     ULCQgHAgMiAgEGFQoJCAsCAxYCAQIeBwIXgAAK
                     CRADSS4BiK3SuQlwAQDP3MPbKyNXvmyNOvUr3sM
                     tnN6FXaAh+DhHQkhdYXLDwEAm1STmy7xI/IV
                    xdkorW16P9q6iHReGNxHX+kl50ZSDVw= =v/u5
                    -----END PGP PUBLIC KEY BLOCK-----
                """)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(KeetaColor.yellow)
                .multilineTextAlignment(.leading)
                .padding(EdgeInsets(top: 0, leading: 24, bottom: 24, trailing: 24))
            }
            .background(KeetaColor.black)
            .cornerRadius(16)
            Image("Powered")
                .resizable()
                .frame(width: 113, height: 24)
                .padding(EdgeInsets(top: 24, leading: 0, bottom: 0, trailing: 0))
        }
        .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        .background(KeetaColor.gray)
        .frame(minWidth: 700, minHeight: 368)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
