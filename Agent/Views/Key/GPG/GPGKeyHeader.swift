import SwiftUI

struct GPGKeyHeader: View {
    
    let key: GPGKey
    
    var body: some View {
        HStack {
            GPGKeyIcon()
            Spacer()
            CopyButton(value: key.value)
        }
        .padding(AgentSpacing.large)
    }
}

#if DEBUG
struct GPGKeyHeader_Previews: PreviewProvider {
    static var previews: some View {
        GPGKeyHeader(key: .init(id: "GPG_ID", value: "GPG_PREVIEW", fullName: "Ty", email: "ty@keeta.com"))
    }
}
#endif
