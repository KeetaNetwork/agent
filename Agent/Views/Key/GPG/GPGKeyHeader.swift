import SwiftUI

struct GPGKeyHeader: View {
    
    let key: GPGKey
    
    var body: some View {
        HStack {
            GPGKeyIcon(uploaded: key.isUploaded)
            Spacer()
            CopyButton(value: key.value)
        }
        .padding(AgentSpacing.large)
    }
}

#if DEBUG
struct GPGKeyHeader_Previews: PreviewProvider {
    static var previews: some View {
        GPGKeyHeader(key: .init(id: "GPG_ID", value: "GPG_PREVIEW", fullName: "Ty", email: "ty@keeta.com", isUploaded: false))
    }
}
#endif
