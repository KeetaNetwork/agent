import Foundation

enum Config {
    case socketAuth(socketPath: String)
    case gpg
    case gpgAgent
    case gnupgPkcs11
    
    var linePrefixToReplace: String {
        switch self {
        case .socketAuth:
            return "export SSH_AUTH_SOCK"
        case .gpg:
            return "agent-program"
        case .gpgAgent:
            return "scdaemon-program"
        case .gnupgPkcs11:
            return "provider-keeta-library"
        }
    }
    
//    let gpgAgentPath = Bundle.main.url(forResource: "gnupg/bin/gpg-agent", withExtension: "")!.path
//    let gpgPath = Bundle.main.url(forResource: "gnupg/bin/gpg", withExtension: "")!.path
    
    var payload: String {
        switch self {
        case .socketAuth(let socketPath):
            return "export SSH_AUTH_SOCK=\(socketPath)"
        case .gpg:
            return "agent-program \(configFolderName)/bin/gpg-connect-agent"
        case .gpgAgent:
            return "scdaemon-program \(configFolderName)/bin/gnupg-pkcs11-scd"
        case .gnupgPkcs11:
            return "providers keeta" + "\n" + "provider-keeta-library \(configFolderName)/lib/libssh-agent-pkcs11-provider.dylib"
        }
    }
    
    var folderPath: String? {
        switch self {
        case .socketAuth:
            return nil
        case .gpg, .gpgAgent, .gnupgPkcs11:
            return configFolderName
        }
    }
    
    var filename: String {
        switch self {
        case .socketAuth:
            return ".zshrc"
        case .gpg:
            return "gpg.conf"
        case .gpgAgent:
            return "gpg-agent.conf"
        case .gnupgPkcs11:
            return "gnupg-pkcs11-scd.conf"
        }
    }
}
