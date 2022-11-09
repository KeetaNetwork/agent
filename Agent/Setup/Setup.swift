import Foundation

enum Command {
    case enableGPGSign
    case gitVersion
    case setSigningKey(key: String)
    case setGPGProgram(path: String)
    case exportGPG(keyId: String)
    // test sign
    // echo -n "Hello world with PKCS11" | ./gpg --armor --clearsign --textmode -u B660BFA02C848FC4D44278979B50949C9847ABD0
    // check keys
    // ./gpg --check-signatures
    // export
    // ./gpg --expert --full-generate-key
    // - inputs
    // check card status
    // ./gpg --card-status
    // setup
    // ./gpg-agent --server gpg-connect-agent
    // - inputs: RELOADAGENT, SCD LEARN
    
    var executable: String {
        switch self {
        case .enableGPGSign, .gitVersion, .setSigningKey, .setGPGProgram:
            return "/usr/bin/git"
        case .exportGPG:
            return "./gpg"
        }
    }
    
    var isAlias: Bool {
        switch self {
        case .enableGPGSign, .gitVersion, .setSigningKey, .setGPGProgram:
            return true
        case .exportGPG:
            return false
        }
    }

    var commands: [String] {
        switch self {
        case .enableGPGSign:
            return ["config", "--global", "commit.gpgsign", "true"]
        case .setSigningKey(let key):
            return ["config", "--global", "user.signingkey", key]
        case .setGPGProgram(let path):
            return ["config", "--global", "gpg.program", path]
        case .gitVersion:
            return ["--version"]
        case .exportGPG(let keyId):
            return ["--export", "--armor", keyId]
        }
    }
}

@discardableResult
private func execute(_ command: Command) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
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
            
            let task = Process()
            let pipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = pipe
            task.arguments = ["-c"] + command.commands
            task.executableURL = executableURL
            task.standardInput = nil
            
            try task.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            // let lines = output.split(whereSeparator: { $0.isNewline })
            continuation.resume(returning: String(data: data, encoding: .utf8) ?? "")
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
    try await execute(.gitVersion)
    
    /// gpg-agent --server gpg-connect-agent
    // > RELOADAGENT
    // > SCD LEARN
    // > EOF
    // -> KEY-FRIEDNLY {key grip}
    
    /// gpg2 --expert --full-generate-key
    // kind of key: 13
    // keygrip: {}
    // Possible actions: Q
    // Key is valid for: 0
    // Key does not expire at all: Y
    // Real name {}
    // Email address {}
    // Comment {return}
    // O
    // !grab key ID
    
    
    /// ./gpg --export --armor B660BFA02C848FC4D44278979B50949C9847ABD0
    
    
//    try await execute(.enableGPGSign)
//
//    let appPath = NSHomeDirectory()
//    let socketPath = (homeDirectory as NSString).appendingPathComponent("socket.ssh") as String
//
//    // SSH_AUTH_SOCK
//    try add("export SSH_AUTH_SOCK=\(socketPath)", to: .init(fileURLWithPath: "\(appPath)/.zshrc"))
//
//    // IdentityAgent
//    try add("Host *\n\tIdentityAgent \(socketPath)", to: .init(fileURLWithPath: "\(appPath)/.ssh/config"))
}

//func updateSigningKey<T: Secret>(using secret: T) {
//    let publicKeyFileStoreController = PublicKeyFileStoreController(homeDirectory: homeDirectory)
//    let keyPath = publicKeyFileStoreController.path(for: secret)
//
//    Task {
//        await execute(.setSigningKey(key: keyPath))
//    }
//}
