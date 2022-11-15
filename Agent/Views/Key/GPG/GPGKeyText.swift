import SwiftUI

struct GPGKeyText: View {
    let key: GPGKey
    
    var body: some View {
        Text(key.displayValue)
            .foregroundColor(KeetaColor.gray40)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, AgentSpacing.large)
            .padding(.bottom, AgentSpacing.large)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
struct GPGKeyText_Previews: PreviewProvider {
    static var previews: some View {
        GPGKeyText(key: .init(id: "GPG_ID", value: "GPG_PREVIEW", fullName: "Ty", email: "ty@keeta.com", isUploaded: true))
    }
}
#endif
