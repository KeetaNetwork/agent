import Foundation

enum Config {
    case socketAuth
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
    
    var payload: String {
        switch self {
        case .socketAuth:
            return "export SSH_AUTH_SOCK=\(socketPath)"
        case .gpg:
            return "agent-program \(gpgAgentConnectPath)"
        case .gpgAgent:
            return "scdaemon-program \(pkcs11SymlinkPath)"
        case .gnupgPkcs11:
            return "providers keeta" + "\n" + "provider-keeta-library \(libsshSymlinkPath)"
        }
    }
    
    var isSystem: Bool {
        switch self {
        case .socketAuth:
            return true
        case .gpg, .gpgAgent, .gnupgPkcs11:
            return false
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
