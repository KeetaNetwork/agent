import SwiftUI

struct KeyDivider: View {
    var body: some View {
        Rectangle()
            .fill(KeetaColor.gray50)
            .frame(height: 1)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: AgentSpacing.large, trailing: 0))
    }
}

#if DEBUG
struct KeyDivider_Previews: PreviewProvider {
    static var previews: some View {
        KeyDivider()
    }
}
#endif
