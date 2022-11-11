import Foundation

let homeDirectory = NSHomeDirectory() + "/Library/KeetaAgent/Data"
let configFolderName = ".keeta_agent"
let gpgAgentPath = Bundle.main.url(forResource: "gnupg/bin/gpg-agent", withExtension: "")!.path
let gpgPath = Bundle.main.url(forResource: "gnupg/bin/gpg", withExtension: "")!.path
let pkcs11Path = Bundle.main.url(forResource: "gnupg/bin/gnupg-pkcs11-scd", withExtension: "")!.path
let libsshPath = Bundle.main.url(forResource: "gnupg/lib/libssh-agent-pkcs11-provider", withExtension: "dylib")!.path

func createHomeDirectory() {
    if !FileManager.default.fileExists(atPath: homeDirectory) {
        try! FileManager.default.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
    }
}

// MARK: Configs

func setupConfigs() throws {
    try ConfigWriter.add(.gpg(agentPath: gpgAgentPath))
    try ConfigWriter.add(.gpgAgent(pkcs11Path: pkcs11Path))
    try ConfigWriter.add(.gnupgPkcs11(libsshPath: libsshPath))
    try ConfigWriter.add(.socketAuth(homeDirectory: homeDirectory))
}

// MARK: GPG

func createGpgKey(fullName: String, email: String) async throws {
    try await CommandExecutor.execute(.killGPGConf).expectIsEmpty()
    
    let keyGrip = try await CommandExecutor.execute(.setupGPGAgent).grap(Grabber.keyGrip)
    
    try await CommandExecutor.execute(.checkCardStatus)
    
    let inputPath = createKeyInput(for: fullName, email: email, keyGrip: "keyGrip")
    let keyId = try await CommandExecutor.execute(.exportGPG(inputFilePath: inputPath)).grap(Grabber.keyId)
    
    try await CommandExecutor.execute(.checkCardStatus).expectFalse(Grabber.hasBadSignatures)
    
    // TODO: grab signed message
    let signedMessageOutput = try await CommandExecutor.execute(.signGPG(message: "GPG setup completed", keyId: keyId))
    print(signedMessageOutput)
}

func createKeyInput(for realName: String, email: String, keyGrip: String) -> String {
    let input = """
Key-Type: default
Subkey-Type: default
Key-Grip: \(keyGrip)
Name-Real: \(realName)
Name-Comment:
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

// MARK: Git

func conifgureGit() {
    //    try await CommandExecutor.execute(.gitEnableGPGSigning)
    //    try await CommandExecutor.execute(.gitSetGPGProgram(path: <#T##String#>))
    //    try await CommandExecutor.execute(.gitSetSigningKey(keyId: <#T##String#>))
}

//func writeSigningKey<T: Secret>(using secret: T) {
//    let publicKeyFileStoreController = PublicKeyFileStoreController(homeDirectory: homeDirectory)
//    let keyPath = publicKeyFileStoreController.path(for: secret)
//
//    Task {
//        await execute(.setSigningKey(key: keyPath))
//    }
//}
