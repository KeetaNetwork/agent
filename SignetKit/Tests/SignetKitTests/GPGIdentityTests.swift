// Keeping the GPG identity's public half in Signet's own folder (signet-update-brief.md step 6),
// so the later OpenPGP signer without GnuPG keeps the same identity: the key's fingerprint and
// creation time, read from GnuPG's machine-readable listing, and the armored key unchanged.
import Foundation
import SignetKit
import Testing

@Suite struct GPGIdentityTests {
  @Test func readsTheIdentityFromGnuPGsListing() throws {
    let listing = String(decoding: try fixture("gpg-list-keys.txt"), as: UTF8.self)
    let armored = String(decoding: try fixture("gpg-public.asc"), as: UTF8.self)
    let id = try GPGIdentity(listing: listing, keyID: "78A10AF1481016DC", armoredPublicKey: armored)
    #expect(id.fingerprint == "B4A41EC0AA59F17DD78EF28078A10AF1481016DC")
    #expect(id.created == Date(timeIntervalSince1970: 1_794_446_782))
    #expect(id.userIDs == ["Signet Test <signet-test@example.com>"])
  }

  @Test func aKeyNotInTheListingIsAnError() throws {
    let listing = String(decoding: try fixture("gpg-list-keys.txt"), as: UTF8.self)
    #expect(throws: (any Error).self) { try GPGIdentity(listing: listing, keyID: "0000000000000000", armoredPublicKey: "") }
  }

  @Test func savedInSignetsFolderWithTheArmoredKeyUnchanged() throws {
    let dir = try shortTemporaryFolder()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let listing = String(decoding: try fixture("gpg-list-keys.txt"), as: UTF8.self)
    let armored = String(decoding: try fixture("gpg-public.asc"), as: UTF8.self)
    let id = try GPGIdentity(listing: listing, keyID: "78A10AF1481016DC", armoredPublicKey: armored)
    try id.save(in: dir)
    #expect(try String(contentsOfFile: dir + "/gpg-public.asc", encoding: .utf8) == armored)
    #expect(try GPGIdentity.load(from: dir) == id)
  }
}
