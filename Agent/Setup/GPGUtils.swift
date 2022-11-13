import Foundation

let configFolderName = ".keeta_agent"
let gpgAgentPath = Bundle.main.url(forResource: "gnupg/bin/gpg-agent", withExtension: "")!.path
let gpgPath = Bundle.main.url(forResource: "gnupg/bin/gpg", withExtension: "")!.path
let gpgAgentConnectPath = Bundle.main.url(forResource: "gnupg/bin/gpg-connect-agent", withExtension: "")!.path
let pkcs11Path = Bundle.main.url(forResource: "gnupg/bin/gnupg-pkcs11-scd", withExtension: "")!.path
let libsshPath = Bundle.main.url(forResource: "gnupg/lib/libssh-agent-pkcs11-provider", withExtension: "dylib")!.path

final class GPGService {
    
    private let keyCurve = "nistp256"
    
    func setupConfigs() {
        do {
            try ConfigWriter.add(.gpg(agentPath: gpgAgentPath))
            try ConfigWriter.add(.gpgAgent(pkcs11Path: pkcs11Path))
            try ConfigWriter.add(.gnupgPkcs11(libsshPath: libsshPath))
            try ConfigWriter.add(.socketAuth(homeDirectory: homeDirectory))
        } catch let error {
            print(error)
        }
    }
    
    func createGpgKey(fullName: String, email: String) async throws -> String {
        try await CommandExecutor.execute(.killGPGConf).expectIsEmpty()
        
        let keyGrip = try await CommandExecutor.execute(.setupGPGAgent).grap(Grabber.keyGrip)
        
        try await CommandExecutor.execute(.restartGPGAgent)
        
        try await CommandExecutor.execute(.checkCardStatus).expectFalse(Grabber.hasBadSignatures)
        
        let existingKeys = try await CommandExecutor.execute(.listGPGKeys).value
        
        let keyId: String
        
        if existingKeys.contains(email) {
            guard let key = Grabber.shortKeyId(from: existingKeys, for: email, keyCurve: keyCurve) else {
                throw NSError(domain: "Couldn't get existing GPG key", code: 500)
            }
            keyId = key
        } else {
            let inputPath = createKeyInput(for: fullName, email: email, keyGrip: keyGrip)
            try await CommandExecutor.execute(.createGPGKey(inputFilePath: inputPath))
            keyId = try await CommandExecutor.execute(.listGPGKeys).grap { Grabber.shortKeyId(from: $0, for: email, keyCurve: keyCurve) }
        }
        
        try await conifgureGit(with: keyId)
        
        return try await CommandExecutor.execute(.exportGPGKey(keyId: keyId)).grap(Grabber.gpgKey)
    }

    func sign(message: String, keyId: String) async throws -> String {
        let signedMessageOutput = try await CommandExecutor.execute(.signGPG(message: message, keyId: keyId))
        return signedMessageOutput.value
    }
    
    // MARK: Helper
    
    private func createKeyInput(for realName: String, email: String, keyGrip: String) -> String {
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
    
    private func conifgureGit(with keyId: String) async throws {
        try await CommandExecutor.execute(.gitEnableGPGSigning)
        try await CommandExecutor.execute(.gitSetGPGProgram(path: gpgPath))
        try await CommandExecutor.execute(.gitSetSigningKey(keyId: keyId))
    }
}
