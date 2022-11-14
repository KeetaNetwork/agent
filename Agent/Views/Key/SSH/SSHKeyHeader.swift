import SwiftUI

struct SSHKeyHeader: View {
    
    let key: SSHKey
    
    var body: some View {
        HStack {
            SSHKeyIcon()
            Spacer()
            CopyButton(value: key.value)
        }
        .padding(AgentSpacing.large)
    }
}

#if DEBUG
struct SSHKeyHeader_Previews: PreviewProvider {
    static var previews: some View {
        SSHKeyHeader(key: .init(value: "SSH_Preview"))
    }
}
#endif
