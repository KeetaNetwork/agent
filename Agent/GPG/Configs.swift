import Foundation

enum Config {
    case socketAuth(socketPath: String)
    case gpg(agentPath: String)
    case gpgAgent(pkcs11Path: String)
    case gnupgPkcs11(libsshPath: String)
    
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
        case .socketAuth(let socketPath):
            return "export SSH_AUTH_SOCK=\(socketPath)"
        case .gpg(let agentPath):
            return "agent-program \(agentPath)"
        case .gpgAgent(let pkcs11Path):
            return "scdaemon-program \(pkcs11Path)"
        case .gnupgPkcs11(let libsshPath):
            return "providers keeta" + "\n" + "provider-keeta-library \(libsshPath)"
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
