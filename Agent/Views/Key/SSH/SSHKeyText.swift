import SwiftUI

struct SSHKeyText: View {
    let key: SSHKey
    
    var body: some View {
        Text(key.value)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(KeetaColor.gray40)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, AgentSpacing.large)
        .padding(.bottom, AgentSpacing.large)
    }
}

#if DEBUG
struct SSHKeyText_Previews: PreviewProvider {
    static var previews: some View {
        SSHKeyText(key: .init(value: "SSH_Preview"))
    }
}
#endif
