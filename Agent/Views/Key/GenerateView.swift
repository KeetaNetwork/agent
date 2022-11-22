import SwiftUI

struct GenerateView: View {
    @ObservedObject var keetaAgent: KeetaAgent = Dependencies.all.keetaAgent
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AgentSpacing.large) {
            VStack(alignment: .leading, spacing: AgentSpacing.small) {
                Text("Agent Setup")
                    .foregroundColor(KeetaColor.yellow)
                    .font(.title)
                Text("Please enter the following information, which will be associated with your GPG key.")
                    .font(.title3)
                    .foregroundColor(KeetaColor.gray40)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: AgentSpacing.medium) {
                Text("Full Name")
                    .foregroundColor(KeetaColor.yellow)
                    .font(.title3)
                TextField("", text: $name)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(KeetaColor.yellow, lineWidth: 1)
                    )
                Text("Email")
                    .foregroundColor(KeetaColor.yellow)
                    .font(.title3)
                TextField("", text: $email)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(KeetaColor.yellow, lineWidth: 1)
                    )
            }
            Button {
                Task {
                    let error = await keetaAgent.createNewKey(for: name, email: email)
                    DispatchQueue.main.async { self.error = error }
                }
            } label: {
                Text("Generate GPG Key")
                    .font(.title3)
                    .foregroundColor(KeetaColor.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            }
            .alert(isPresented: .init(get: { error != nil }, set: { error = $0 ? error : nil })) {
                Alert(title: Text("Agent Error"), message: Text(error ?? ""), dismissButton: .default(Text("Ok")))
            }
            .buttonStyle(.plain)
            .background(KeetaColor.red)
            .cornerRadius(40)
        }
        .padding(AgentSpacing.large)
        .background(KeetaColor.black)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KeetaColor.gray50, lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

#if DEBUG
struct GenerateView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateView()
    }
}
#endif
