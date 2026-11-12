import Foundation

/// The GPG identity's public half, kept in Signet's own folder (signet-update-brief.md step 6): the
/// later OpenPGP signer that replaces GnuPG needs exactly the key's creation time and fingerprint
/// to go on signing as the same identity.
public struct GPGIdentity: Codable, Sendable, Equatable {
  public let keyID: String
  public let fingerprint: String
  public let created: Date
  public let userIDs: [String]
  public let armoredPublicKey: String

  /// Reads the key `keyID` (its long id, or the short one it ends with) from `gpg --with-colons --list-keys` output.
  public init(listing: String, keyID: String, armoredPublicKey: String) throws {
    var found: (id: String, created: Date, fingerprint: String?, uids: [String])?
    var inKey = false
    for line in listing.split(separator: "\n") {
      let f = line.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
      switch f.first {
      case "pub":
        guard found == nil else {
          inKey = false
          continue
        }
        inKey = f.count > 5 && !keyID.isEmpty && f[4].uppercased().hasSuffix(keyID.uppercased())
        if inKey, let t = TimeInterval(f[5]) { found = (f[4].uppercased(), Date(timeIntervalSince1970: t), nil, []) }
      case "fpr" where inKey && found?.fingerprint == nil:
        if f.count > 9 { found?.fingerprint = f[9] }
      case "uid" where inKey:
        if f.count > 9 { found?.uids.append(f[9]) }
      case "sub":
        if inKey { inKey = false }
      default:
        break
      }
    }
    guard let found, let fingerprint = found.fingerprint else { throw SignetError.malformed }
    self.keyID = found.id
    self.fingerprint = fingerprint
    self.created = found.created
    self.userIDs = found.uids
    self.armoredPublicKey = armoredPublicKey
  }

  /// Writes `gpg-public.asc` (the armored key, unchanged) and `gpg-identity.json` in `folder`.
  public func save(in folder: String) throws {
    try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
    try armoredPublicKey.write(toFile: folder + "/gpg-public.asc", atomically: true, encoding: .utf8)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .secondsSince1970
    try encoder.encode(Saved(self)).write(to: URL(fileURLWithPath: folder + "/gpg-identity.json"))
  }

  public static func load(from folder: String) throws -> GPGIdentity {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    let saved = try decoder.decode(Saved.self, from: Data(contentsOf: URL(fileURLWithPath: folder + "/gpg-identity.json")))
    let armored = try String(contentsOfFile: folder + "/gpg-public.asc", encoding: .utf8)
    return GPGIdentity(keyID: saved.keyID, fingerprint: saved.fingerprint, created: saved.created, userIDs: saved.userIDs, armoredPublicKey: armored)
  }

  private init(keyID: String, fingerprint: String, created: Date, userIDs: [String], armoredPublicKey: String) {
    self.keyID = keyID
    self.fingerprint = fingerprint
    self.created = created
    self.userIDs = userIDs
    self.armoredPublicKey = armoredPublicKey
  }

  /// What the JSON file holds; the key itself is in `gpg-public.asc`.
  private struct Saved: Codable {
    let keyID: String
    let fingerprint: String
    let created: Date
    let userIDs: [String]
    init(_ id: GPGIdentity) {
      keyID = id.keyID
      fingerprint = id.fingerprint
      created = id.created
      userIDs = id.userIDs
    }
  }
}
