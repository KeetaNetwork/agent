import SwiftUI

struct KeyView: View {
    
    let gpgKey: GPGKey
    let sshKey: SSHKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: AgentSpacing.large) {
            container {
                Group {
                    GPGKeyHeader(key: gpgKey)
                    KeyDivider()
                    GPGKeyText(key: gpgKey)
                }
            }
            container {
                Group {
                    SSHKeyHeader(key: sshKey)
                    KeyDivider()
                    SSHKeyText(key: sshKey)
                }
            }
        }
    }
}

extension KeyView {
    private func container<Content: View>(_ content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(KeetaColor.black)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KeetaColor.gray50, lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

#if DEBUG
struct KeyView_Previews: PreviewProvider {
    static var previews: some View {
        KeyView(
            gpgKey: .init(id: "GPG_ID", value: "GPG_PREVIEW", fullName: "Ty", email: "ty@keeta.com"),
            sshKey: .init(value: "SSH_PREVIEW")
        )
    }
}
#endif
