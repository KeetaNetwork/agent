import SwiftUI

struct GPGKeyText: View {
    let key: GPGKey
    
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
struct GPGKeyText_Previews: PreviewProvider {
    static var previews: some View {
        GPGKeyText(key: .init(value: "GPG_PREVIEW", fullName: "Ty", email: "ty@keeta.com"))
    }
}
#endif
