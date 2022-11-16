import SwiftUI

struct GPGKeyHeader: View {
    
    let key: GPGKey
    
    var body: some View {
        HStack {
            KeyIcon(keyType: .gpg, uploaded: key.isUploaded)
            Spacer()
            CopyButton(value: key.value)
        }
        .padding(AgentSpacing.large)
    }
}

#if DEBUG
struct GPGKeyHeader_Previews: PreviewProvider {
    static var previews: some View {
        GPGKeyHeader(key: .preview())
    }
}
#endif
