import XCTest
@testable import Agent

final class SetupTest: XCTestCase {
    func test_commands() async throws {
        try setupConfigs()
        
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        try await createGpgKey(fullName: "Test", email: "test@keeta.com")
        
//        try await CommandExecutor.execute(.killGPGConf)
//
//        let keyGrip = try await CommandExecutor.execute(.setupGPGAgent).grap(Grabber.keyGrip)
//
//        try await CommandExecutor.execute(.checkCardStatus)
//
//        let inputFile = createKeyInput(for: "Test User", email: "test@keeta.com", keyGrip: keyGrip)
//        let keyId = try await CommandExecutor.execute(.exportGPG(inputFilePath: inputFile)).grap(Grabber.keyId)
    
    func test_setupGPGAgent() async throws {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        _ = try await CommandExecutor.execute(.setupGPGAgent).grap(Grabber.keyGrip)
    }
    }
}
