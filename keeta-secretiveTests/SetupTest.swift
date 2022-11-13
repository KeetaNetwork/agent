import XCTest
@testable import Agent

final class SetupTest: XCTestCase {
    func test_setup() async throws {
        await wait()
        
        _ = try await GPGService().createGpgKey(fullName: "Keeta Test", email: "\(UUID().uuidString)@keeta.com")
    }
    
    func test_listGPGKeys() async throws {
        _ = try await CommandExecutor.execute(.listGPGKeys)
    }
    
    // MARK: Helper
    
    private func wait(_ duration: TimeInterval = 1) async {
        try! await Task.sleep(nanoseconds: UInt64(duration) * 1_000_000_000)
    }
}
