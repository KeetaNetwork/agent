import XCTest
@testable import Agent

final class SetupTest: XCTestCase {
    func test_configs() async throws {
        try ConfigWriter.add(config: .gpg(agentPath: gpgAgentPath))
        try ConfigWriter.add(config: .gpgAgent(pkcs11Path: pkcs11Path))
        try ConfigWriter.add(config: .gnupgPkcs11(libsshPath: libsshPath))
        //    try ConfigWriter.add(config: .socketAuth(homeDirectory: homeDirectory))
    }
}
