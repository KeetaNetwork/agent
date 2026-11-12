// The device's key as a Keeta account (signet-update-brief.md step 8; spec 141 CG-121): its
// address as the Keeta SDK writes it, and statements signed the way a secp256r1 account's
// signature verifies, P1363 r‖s over SHA3-256 of the data.
import Crypto
import Foundation
import SignetKit
import Testing

private struct Vectors: Decodable {
  struct Account: Decodable {
    let publicKey: String
    let address: String
  }
  struct Hash: Decodable {
    let name: String
    let hex: String
    let digest: String
  }
  let accounts: [Account]
  let sha3_256: [Hash]
}

private func vectors() throws -> Vectors {
  try JSONDecoder().decode(Vectors.self, from: fixture("keeta-accounts.json"))
}

@Suite struct KeetaAccountTests {
  @Test func addressIsTheOneTheKeetaSDKGivesThePublicKey() throws {
    for v in try vectors().accounts {
      #expect(try KeetaAccount.address(publicKey: Data(hex: v.publicKey)) == v.address)
    }
  }

  @Test func aKeyThatIsNotAnUncompressedP256PointHasNoAddress() {
    #expect(throws: (any Error).self) { try KeetaAccount.address(publicKey: Data(repeating: 4, count: 33)) }
  }

  @Test func sha3IsFIPS202AcrossBlockBoundaries() throws {
    for v in try vectors().sha3_256 {
      #expect(KeetaAccount.sha3_256(Data(hex: v.hex)).hex == v.digest, "\(v.name)")
    }
  }

  @Test func aStatementIsSignedOverItsSHA3DigestAfterAskingWithTheReason() throws {
    let key = MemoryKey()
    let statement = Data("register this device with Workspace".utf8)
    let signature = try KeetaAccount.sign(statement, with: key, reason: "register this Mac")
    #expect(signature.count == 64)
    #expect(key.verifies(signature, digest: KeetaAccount.sha3_256(statement)))
    #expect(!key.verifies(signature, digest: Data(SHA256.hash(data: statement))))
    #expect(key.reasons == ["register this Mac"])
  }
}
