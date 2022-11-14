import Foundation

enum Config {
    case socketAuth(socketPath: String)
    case gpg(agentPath: String)
    case gpgAgent(pkcs11Path: String)
    case gnupgPkcs11(libsshPath: String)
    
    var linesToRemoveWithPrefix: [String] {
        switch self {
        case .socketAuth:
            return ["export SSH_AUTH_SOCK"]
        case .gpg:
            return ["agent-program"]
        case .gpgAgent:
            return ["scdaemon-program"]
        case .gnupgPkcs11:
            return ["providers", "provider-keeta-library"]
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
        var existingLines = existingString.split(whereSeparator: \.isNewline)
        
        config.linesToRemoveWithPrefix.forEach { prefixToRemove in
            let indexesToRemove: [Int] = existingLines.enumerated()
                .compactMap { $0.element.hasPrefix(prefixToRemove) ? $0.offset : nil }
            
            indexesToRemove.forEach { existingLines.remove(at: $0) }
        }
        
        // TODO: check if line isn't a comment
        guard !existingString.contains(text) else { return }
        
        try handle.seekToEnd()
        
        let data = "\n\(text)\n".data(using: .utf8)!
        handle.write(data)
    }
}
