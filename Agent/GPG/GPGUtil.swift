import Foundation
import OSLog

let configFolderName = ".keeta_agent"
let symlinkFolderName = "symlinks"
let symlinkPath = "\(NSHomeDirectory())/\(configFolderName)/\(symlinkFolderName)"

let gpgAgentSymlinkPath = "\(symlinkPath)/gpg-agent"
let gpgAgentFilePath = Bundle.main.url(forResource: "gnupg/bin/gpg-agent", withExtension: "")!.path

let gpgSymlinkPath = "\(symlinkPath)/gpg"
let gpgFilePath = Bundle.main.url(forResource: "gnupg/bin/gpg", withExtension: "")!.path

let gpgAgentConnectSymlinkPath = "\(symlinkPath)/gpg-connect-agent"
let gpgAgentConnectFilePath = Bundle.main.url(forResource: "gnupg/bin/gpg-connect-agent", withExtension: "")!.path

let pkcs11SymlinkPath = "\(symlinkPath)/gnupg-pkcs11-scd"
let pkcs11FilePath = Bundle.main.url(forResource: "gnupg/bin/gnupg-pkcs11-scd", withExtension: "")!.path

let libsshSymlinkPath = "\(symlinkPath)/libssh-agent-pkcs11-provider.dylib"
let libsshFilePath = Bundle.main.url(forResource: "gnupg/lib/libssh-agent-pkcs11-provider", withExtension: "dylib")!.path

final class GPGUtil {
    
    private static let keyCurve = "nistp256"
    
    static func writeConfigs() throws {
        try ConfigWriter.add(.gpg)
        try ConfigWriter.add(.gpgAgent)
        try ConfigWriter.add(.gnupgPkcs11)
        try ConfigWriter.add(.socketAuth)
    }
    
    static func createSymlinks() async throws {
        let fileManager = FileManager.default
        
        try? fileManager.removeItem(atPath: symlinkPath)
        try fileManager.createDirectory(atPath: symlinkPath, withIntermediateDirectories: false)
        
        let files: [(String, String)] = [
            (gpgAgentFilePath, gpgAgentSymlinkPath),
            (gpgFilePath, gpgSymlinkPath),
            (gpgAgentConnectFilePath, gpgAgentConnectSymlinkPath),
            (pkcs11FilePath, pkcs11SymlinkPath),
            (libsshFilePath, libsshSymlinkPath),
            (socketPath, socketSymlinkPath)
        ]
        
        for (source, destination) in files {
            try await CommandExecutor.execute(.createSymlink(source: source, destination: destination))
        }
    }
    
    static func createGpgKey(fullName: String, email: String) async throws -> GPGKey {
        try await CommandExecutor.execute(.killGPGConf)
        
        let keyGrip = try await CommandExecutor.execute(.setupGPGAgent).grap(Grabber.keyGrip)
        
        try await CommandExecutor.execute(.restartGPGAgent)
        
        try await CommandExecutor.execute(.checkCardStatus).expectFalse(Grabber.hasBadSignatures)
        
        let existingKeys = try await CommandExecutor.execute(.listGPGKeys).value
        
        let keyId: String
        
        if existingKeys.contains(email) {
            guard let key = Grabber.shortKeyId(from: existingKeys, for: email, keyCurve: keyCurve) else {
                throw NSError(domain: "Couldn't parse existing GPG key from output: \(existingKeys)", code: 500)
            }
            keyId = key
        } else {
            let inputPath = createKeyInput(for: fullName, email: email, keyGrip: keyGrip)
            try await CommandExecutor.execute(.createGPGKey(inputFilePath: inputPath))
            keyId = try await CommandExecutor.execute(.listGPGKeys).grap { Grabber.shortKeyId(from: $0, for: email, keyCurve: keyCurve) }
        }
        
        try await conifgureGit(with: keyId)
        
        let publicKey = try await CommandExecutor.execute(.exportGPGKey(keyId: keyId)).grap(Grabber.gpgKey)
        
        return .init(id: keyId, value: publicKey, fullName: fullName, email: email, isUploaded: false)
    }

    static func keyExists(for keyId: String) async -> Bool {
        do {
            try await CommandExecutor.execute(.killGPGConf)
            
            try await CommandExecutor.execute(.restartGPGAgent)
            
            try await CommandExecutor.execute(.checkCardStatus).expectFalse(Grabber.hasBadSignatures)
            
            let existingKeys = try await CommandExecutor.execute(.listGPGKeys).value
            
            return existingKeys.contains(keyId)
        } catch {
            return false
        }
    }
    
    static func sign(message: String, keyId: String) async throws -> String {
        let signedMessageOutput = try await CommandExecutor.execute(.signGPG(message: message, keyId: keyId))
        return signedMessageOutput.value
    }
    
    // MARK: Helper
    
    private static func createKeyInput(for realName: String, email: String, keyGrip: String) -> String {
        let input = """
    Key-Type: ECDSA
    Key-Curve: \(keyCurve)
    Key-Grip: \(keyGrip)
    Name-Real: \(realName)
    Name-Email: \(email)
    Expire-Date: 0
    """
        let data = input.data(using: .utf8)!
        let fileName = "gpg_key_input"
        let inputFilePath = ConfigWriter.configDirectory.appending("/\(configFolderName)/\(fileName)")
        try? FileManager.default.removeItem(atPath: inputFilePath)
        FileManager.default.createFile(atPath: inputFilePath, contents: data)
        return inputFilePath
    }
    
    private static func conifgureGit(with keyId: String) async throws {
        try await CommandExecutor.execute(.gitEnableGPGSigning)
        try await CommandExecutor.execute(.gitSetGPGProgram(path: gpgSymlinkPath))
        try await CommandExecutor.execute(.gitSetSigningKey(keyId: keyId))
    }
}
