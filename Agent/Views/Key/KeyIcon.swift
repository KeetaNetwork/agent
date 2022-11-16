import SwiftUI

struct KeyIcon: View {
    
    enum KeyType {
        case gpg, ssh
        
        var title: String {
            switch self {
            case .gpg: return "GPG Key"
            case .ssh: return "SSH Key"
            }
        }
    }
    
    let keyType: KeyType
    let uploaded: Bool
    
    var body: some View {
        HStack {
            Image("Key")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text(keyType.title)
                .foregroundColor(KeetaColor.yellow)
                .font(.title3)
            if uploaded {
                Image(systemName: "checkmark.circle")
                    .help("Uploaded to Github")
                    .foregroundColor(KeetaColor.green)
            }
        }
    }
}

#if DEBUG
struct SSHKeyIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            KeyIcon(keyType: .gpg, uploaded: false)
            KeyIcon(keyType: .gpg, uploaded: true)
            KeyIcon(keyType: .ssh, uploaded: false)
            KeyIcon(keyType: .ssh, uploaded: true)
        }
    }
}
#endif
