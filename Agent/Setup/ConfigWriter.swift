import Foundation

enum Config {
    /*
     export SSH_AUTH_SOCK=/Users/dscheutz/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
     */
    case socketAuth(homeDirectory: String)
    /*
     auto-key-retrieve
     no-emit-version
     agent-program /Users/dscheutz/gnupg-2.3.8/bin/gpg-agent
     */
    case gpg
    /*
     scdaemon-program /Users/dscheutz/gnupg-pkcs11-scd-0.10.0/bin/gnupg-pkcs11-scd
     pinentry-program /opt/homebrew/bin/pinentry
     */
    case gpgAgent
    /*
     providers keeta
     provider-keeta-library /Users/dscheutz/ssh-agent-pkcs11-0.0737d85a4a/lib/libssh-agent-pkcs11-provider.dylib
     */
    case gnupgPkcs11
    
    var payload: String {
        switch self {
        case .socketAuth(let homeDirectory):
            let socketPath = (homeDirectory as NSString).appendingPathComponent("socket.ssh")
            return "export SSH_AUTH_SOCK=\(socketPath)"
        // IdentityAgent
        // "Host *\n\tIdentityAgent \(socketPath)"
        case .gpg:
            return ""
        case .gpgAgent:
            return ""
        case .gnupgPkcs11:
            return ""
        }
    }
    
    var filePath: String {
        switch self {
        case .socketAuth:
            return ".zshrc"
        // IdentityAgent
        // .ssh/config
        case .gpg:
            return ""
        case .gpgAgent:
            return ""
        case .gnupgPkcs11:
            return ""
        }
    }
}

final class ConfigWriter {
    
    static func add(config: Config) throws {
        let fileURL = URL(fileURLWithPath: "\(NSHomeDirectory())/\(config.filePath)")
        let text = config.payload
        
        let handle: FileHandle
        handle = try FileHandle(forUpdating: fileURL)
        
        let existing = try handle.readToEnd() ?? .init()
        let existingString = String(data: existing, encoding: .utf8) ?? ""
        let existingLines = existingString.split(whereSeparator: \.isNewline)
        
        guard !existingString.contains(text) else { return }
        
        try handle.seekToEnd()
        
        let data = "\n\(text)\n".data(using: .utf8)!
        handle.write(data)
    }
}
