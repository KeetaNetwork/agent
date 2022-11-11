import Foundation

enum Config {
    /*
     export SSH_AUTH_SOCK=/Users/dscheutz/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
     */
    case socketAuth(homeDirectory: String)
    
    case gpg(agentPath: String)
    case gpgAgent(pkcs11Path: String)
    case gnupgPkcs11(libsshPath: String)
    
    var payload: String {
        switch self {
        case .socketAuth(let homeDirectory):
            let socketPath = (homeDirectory as NSString).appendingPathComponent("socket.ssh")
            return "export SSH_AUTH_SOCK=\(socketPath)"
            
        // IdentityAgent
        // "Host *\n\tIdentityAgent \(socketPath)"
        
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
        // IdentityAgent
        // .ssh/config
        case .gpg, .gpgAgent, .gnupgPkcs11:
            return ".keeta_agent"
        }
    }
    
    var filename: String {
        switch self {
        case .socketAuth:
            return ".zshrc"
        // IdentityAgent
        // .ssh/config
        case .gpg:
            return "gpg.conf"
        case .gpgAgent:
            return "gpg-agent.conf"
        case .gnupgPkcs11:
            return "gnupg-pkcs11-scd.conf"
        }
    }
}

final class ConfigWriter {

    private static let configDirectory = "\(NSHomeDirectory())"
    
    static func add(config: Config) throws {
        let fileManager = FileManager.default
        
        var filePath = configDirectory
        if let directory = config.folderPath {
            filePath.append("/\(directory)")
            
            if !fileManager.fileExists(atPath: filePath) {
                try fileManager.createDirectory(at: .init(fileURLWithPath: filePath), withIntermediateDirectories: true)
            }
        }
        
        let fileURL = URL(fileURLWithPath: filePath.appending("/\(config.filename)"))
        let text = config.payload
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            let data = text.data(using: .utf8)!
            fileManager.createFile(atPath: fileURL.path, contents: data)
            return
        }
        
        let handle: FileHandle
        handle = try FileHandle(forUpdating: fileURL)
        
        let existing = try handle.readToEnd() ?? .init()
        let existingString = String(data: existing, encoding: .utf8) ?? ""
        // TODO: check if line isn't a comment
//        let existingLines = existingString.split(whereSeparator: \.isNewline)
        
        guard !existingString.contains(text) else { return }
        
        try handle.seekToEnd()
        
        let data = "\n\(text)\n".data(using: .utf8)!
        handle.write(data)
    }
}
