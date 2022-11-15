import Foundation

enum Config {
    case socketAuth(socketPath: String)
    case gpg(agentPath: String)
    case gpgAgent(pkcs11Path: String)
    case gnupgPkcs11(libsshPath: String)
    
    var linePrefixToReplace: String? {
        switch self {
        case .socketAuth:
            return "export SSH_AUTH_SOCK"
        case .gpg, .gpgAgent, .gnupgPkcs11:
            return nil
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
    
    var isCustom: Bool {
        switch self {
        case .socketAuth:
            return false
        case .gpg, .gpgAgent, .gnupgPkcs11:
            return true
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

final class ConfigWriter {

    static let configDirectory = "\(NSHomeDirectory())"
    
    static func add(_ config: Config) throws {
        let fileManager = FileManager.default
        
        var filePath = configDirectory
        if let directory = config.folderPath {
            filePath.append("/\(directory)")
            
            if !fileManager.fileExists(atPath: filePath) {
                try fileManager.createDirectory(
                    at: .init(fileURLWithPath: filePath),
                    withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 448]
                )
            }
        }
        
        let fileURL = URL(fileURLWithPath: filePath.appending("/\(config.filename)"))
        let fileExists = fileManager.fileExists(atPath: fileURL.absoluteString)
        
        let text = config.payload + "\n"
        
        if config.isCustom {
            if !fileExists {
                let data = text.data(using: .utf8)!
                fileManager.createFile(atPath: fileURL.path, contents: data)
            }
        } else {
            let handle: FileHandle
            handle = try FileHandle(forUpdating: fileURL)
            
            let existing = try handle.readToEnd() ?? .init()
            let existingString = String(data: existing, encoding: .utf8) ?? ""
            var existingLines = existingString.split(whereSeparator: \.isNewline)
            
            guard !existingLines.contains(where: { $0 == config.payload }) else { return }
            
            if let prefix = config.linePrefixToReplace,
               let indexToReplace = existingLines.firstIndex(where: { $0.hasPrefix(prefix) }) {
                existingLines.remove(at: indexToReplace)
            }
            
            try handle.seekToEnd()
            
            let data = "\n\(text)".data(using: .utf8)!
            handle.write(data)
        }
    }
}
