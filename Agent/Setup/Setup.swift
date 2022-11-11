import Foundation

let homeDirectory = NSHomeDirectory() + "/Library/Agent/Data"
let gpgAgentPath = Bundle.main.url(forResource: "gnupg/bin/gpg-agent", withExtension: "")!.path
let gpgPath = Bundle.main.url(forResource: "gnupg/bin/gpg", withExtension: "")!.path
let pkcs11Path = Bundle.main.url(forResource: "gnupg/bin/gnupg-pkcs11-scd", withExtension: "")!.path
let libsshPath = Bundle.main.url(forResource: "gnupg/lib/libssh-agent-pkcs11-provider", withExtension: "dylib")!.path

func createHomeDirectory() {
    if !FileManager.default.fileExists(atPath: homeDirectory) {
        try! FileManager.default.createDirectory(at: .init(fileURLWithPath: homeDirectory), withIntermediateDirectories: true)
    }
}

func setupKeeta() async throws {
    // MARK: GPG
    
    try await CommandExecutor.execute(.killGPGConf).expectIsEmpty()
    
    // TODO: figure out how to provide input
    let keyGrip = try await CommandExecutor.execute(.setupGPGAgent).grap(Grabber.keyGrip)
    
    try await CommandExecutor.execute(.checkCardStatus)
    
    // TODO: figure out how to provide input or use --batch
    let keyId = try await CommandExecutor.execute(.exportGPG).grap(Grabber.keyId)
    
    // TODO: verify no bad keys?
//    try await CommandExecutor.execute(.checkCardStatus)
    
    // TODO: grab signed message
    let signedMessageOutput = try await CommandExecutor.execute(.signGPG(message: "GPG setup completed", keyId: keyId))
    
    // MARK: SSH Socket
    
//    try await CommandExecutor.execute(.socketAuth(path: <#T##String#>))
    /// Error Domain=NSPOSIXErrorDomain Code=13 "Permission denied"
    /// https://stackoverflow.com/questions/60791763/not-able-to-open-an-app-using-process-in-swift-returns-error-domain-nsposixerr
//    let appPath = NSHomeDirectory()
//    let socketPath = (homeDirectory as NSString).appendingPathComponent("socket.ssh") as String
//    try await CommandExecutor.execute(.socketAuth(path: socketPath))
    
    // MARK: Git Config
    
//    try await CommandExecutor.execute(.gitEnableGPGSigning)
//    try await CommandExecutor.execute(.gitSetGPGProgram(path: <#T##String#>))
//    try await CommandExecutor.execute(.gitSetSigningKey(keyId: <#T##String#>))
    
    // MARK: Configs
    
//    try ConfigWriter.add(config: .gpg)
//    try ConfigWriter.add(config: .gpgAgent)
//    try ConfigWriter.add(config: .gnupgPkcs11)
//    try ConfigWriter.add(config: .socketAuth(homeDirectory: homeDirectory))
}

//func updateSigningKey<T: Secret>(using secret: T) {
//    let publicKeyFileStoreController = PublicKeyFileStoreController(homeDirectory: homeDirectory)
//    let keyPath = publicKeyFileStoreController.path(for: secret)
//
//    Task {
//        await execute(.setSigningKey(key: keyPath))
//    }
//}
