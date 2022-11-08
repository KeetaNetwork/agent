import Foundation

enum Command {
    case enableGPGSign
    case gitVersion
    case setSigningKey(key: String)
    
    var executable: String {
        switch self {
        case .enableGPGSign, .gitVersion, .setSigningKey:
            return "/opt/homebrew/bin/git"
        }
    }
    
    var isAlias: Bool {
        switch self {
        case .enableGPGSign, .gitVersion, .setSigningKey:
            return true
        }
    }
    
    var commands: [String] {
        switch self {
        case .enableGPGSign:
            return ["config", "--global", "commit.gpgsign", "true"]
        case .setSigningKey(let key):
            return ["config", "--global", "user.signingkey", key]
        case .gitVersion:
            return ["--version"]
        }
    }
}

private func execute(_ command: Command) async throws {
    _ = try await withCheckedThrowingContinuation { continuation in
        do {
            let executableURL: URL
            if command.isAlias {
                let url = URL(fileURLWithPath: command.executable)
                executableURL = try URL(resolvingAliasFileAt: url)
            } else {
                executableURL = URL(fileURLWithPath: command.executable)
            }
            
            guard FileManager.default.fileExists(atPath: executableURL.path) else {
                throw NSError(domain: "Executable doesn't exist.", code: 4)
            }
            
            try Process.run(executableURL, arguments: command.commands) { _ in
                continuation.resume(returning: true)
            }
        } catch let error {
            continuation.resume(throwing: error)
        }
    }
}

private func add(_ text: String, to fileURL: URL) throws {
    let handle: FileHandle
    handle = try FileHandle(forUpdating: fileURL)
    
    let existing = try handle.readToEnd() ?? .init()
    let existingString = String(data: existing, encoding: .utf8) ?? ""
    
    guard !existingString.contains(text) else { return }
    
    try handle.seekToEnd()
    
    let data = "\n# Secretive Keeta Config\n\(text)\n".data(using: .utf8)!
    
    handle.write(data)
}

let homeDirectory = NSHomeDirectory() + "/Library/Agent/Data"

func createHomeDirectory() {
    if !FileManager.default.fileExists(atPath: homeDirectory) {
        try! FileManager.default.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
    }
}

func setupKeeta() async throws {
    try await execute(.enableGPGSign)
    
    let appPath = NSHomeDirectory()
    let socketPath = (homeDirectory as NSString).appendingPathComponent("socket.ssh") as String
    
    // SSH_AUTH_SOCK
    try add("export SSH_AUTH_SOCK=\(socketPath)", to: .init(fileURLWithPath: "\(appPath)/.zshrc"))
    
    // IdentityAgent
    try add("Host *\n\tIdentityAgent \(socketPath)", to: .init(fileURLWithPath: "\(appPath)/.ssh/config"))
}

//func updateSigningKey<T: Secret>(using secret: T) {
//    let publicKeyFileStoreController = PublicKeyFileStoreController(homeDirectory: homeDirectory)
//    let keyPath = publicKeyFileStoreController.path(for: secret)
//
//    Task {
//        await execute(.setSigningKey(key: keyPath))
//    }
//}
