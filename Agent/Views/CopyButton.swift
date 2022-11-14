import SwiftUI

struct CopyButton: View {
    
    let value: String
    
    @State private var copied = false
    
    var body: some View {
        Button(action: {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(value, forType: .string)
            copied.toggle()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
                copied.toggle()
            }
        }) {
            HStack {
                Image("Copy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .opacity(copied ? 0 : 1)
                
                Text(copied ? "Copied!" : "Copy")
                    .font(.title3)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(KeetaColor.red)
    }
}

#if DEBUG
struct KeyCopy_Previews: PreviewProvider {
    static var previews: some View {
        CopyButton(value: "COPY")
    }
}
#endif
