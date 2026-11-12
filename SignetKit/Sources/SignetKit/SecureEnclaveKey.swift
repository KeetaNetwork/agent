#if os(macOS)
  import Crypto
  import Foundation
  import LocalAuthentication
  import Security

  /// The device's keys in the Secure Enclave, found by Keeta Agent's key tag in its keychain access
  /// group. Workspace for Mac, signed by the same Apple team and listing the same group, finds the
  /// same key, so nobody gets a second one (signet-update-brief.md, "Must not change").
  public final class SecureEnclaveKeyStore: @unchecked Sendable {
    /// How Keeta Agent tagged its key; changing it strands existing keys.
    public static let keyTag = "com.keeta.agent.key"
    /// Keeta Agent's keychain access group, with the Apple team's prefix.
    public static let keetaAgentAccessGroup = "2BG69HN56W.com.keeta.agent"

    private let accessGroup: String?
    private let tag = Data(SecureEnclaveKeyStore.keyTag.utf8)

    /// - Parameter accessGroup: The keychain group to look in and make keys in. The standalone app
    ///   passes nil (its default group is this one); Workspace for Mac passes
    ///   `keetaAgentAccessGroup`.
    public init(accessGroup: String?) {
      self.accessGroup = accessGroup
    }

    /// The Secure Enclave keys under Keeta Agent's tag, oldest name first.
    public func keys() -> [SecureEnclaveKey] {
      var query: [CFString: Any] = [
        kSecClass: kSecClassKey,
        kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
        kSecAttrApplicationTag: tag,
        kSecReturnRef: true,
        kSecReturnAttributes: true,
        kSecMatchLimit: kSecMatchLimitAll,
      ]
      if let accessGroup { query[kSecAttrAccessGroup] = accessGroup }
      var found: CFTypeRef?
      guard SecItemCopyMatching(query as CFDictionary, &found) == errSecSuccess,
        let items = found as? [[CFString: Any]]
      else { return [] }
      return items.compactMap { item in
        guard let ref = item[kSecValueRef], CFGetTypeID(ref as CFTypeRef) == SecKeyGetTypeID() else { return nil }
        let key = ref as! SecKey
        guard let pub = SecKeyCopyPublicKey(key), let x963 = SecKeyCopyExternalRepresentation(pub, nil) as Data?
        else { return nil }
        let label = item[kSecAttrApplicationLabel] as? Data ?? Data()
        return SecureEnclaveKey(
          id: label.base64EncodedString(), name: item[kSecAttrLabel] as? String ?? "Signet", publicKey: x963,
          tag: tag, accessGroup: accessGroup)
      }
    }

    /// Makes a key in the Secure Enclave that signs only after Touch ID or the login password.
    public func makeKey(named name: String) throws -> SecureEnclaveKey {
      var error: Unmanaged<CFError>?
      guard
        let access = SecAccessControlCreateWithFlags(
          kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.privateKeyUsage, .userPresence], &error)
      else { throw error!.takeRetainedValue() as Error }
      var attributes: [CFString: Any] = [
        kSecAttrLabel: name,
        kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits: 256,
        kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
        kSecAttrApplicationTag: tag,
        kSecPrivateKeyAttrs: [kSecAttrIsPermanent: true, kSecAttrAccessControl: access] as [CFString: Any],
      ]
      if let accessGroup {
        attributes[kSecAttrAccessGroup] = accessGroup
        attributes[kSecUseDataProtectionKeychain] = true
      }
      guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
        throw error!.takeRetainedValue() as Error
      }
      guard let pub = SecKeyCopyPublicKey(key), let x963 = SecKeyCopyExternalRepresentation(pub, nil) as Data? else {
        throw SignetError.notP256
      }
      return keys().first { $0.publicKey == x963 }
        ?? SecureEnclaveKey(id: "", name: name, publicKey: x963, tag: tag, accessGroup: accessGroup)
    }
  }

  /// One Secure Enclave key. Signing asks for Touch ID, and a second request within a few seconds
  /// (git signs a commit, then a push asks again) reuses the same approval.
  public final class SecureEnclaveKey: SignetKey, @unchecked Sendable {
    public let id: String
    public let name: String
    public let publicKey: Data
    private let tag: Data
    private let accessGroup: String?
    private let lock = NSLock()
    private var approval: (context: LAContext, until: UInt64)?

    /// How long one Touch ID approval signs for.
    static let reuse: TimeInterval = 5

    init(id: String, name: String, publicKey: Data, tag: Data, accessGroup: String?) {
      self.id = id
      self.name = name
      self.publicKey = publicKey
      self.tag = tag
      self.accessGroup = accessGroup
    }

    public func signature(forDigest digest: Data, reason: String) throws -> Data {
      lock.lock()
      defer { lock.unlock() }
      let now = clock_gettime_nsec_np(CLOCK_MONOTONIC)
      let context: LAContext
      if let approval, approval.until > now {
        context = approval.context
      } else {
        context = LAContext()
        context.localizedCancelTitle = "Deny"
        context.touchIDAuthenticationAllowableReuseDuration = 3
        approval = (context, now + UInt64(Self.reuse * 1_000_000_000))
      }
      context.localizedReason = reason

      var query: [CFString: Any] = [
        kSecClass: kSecClassKey,
        kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
        kSecAttrApplicationTag: tag,
        kSecUseAuthenticationContext: context,
        kSecReturnRef: true,
        kSecMatchLimit: kSecMatchLimitAll,
      ]
      if let accessGroup { query[kSecAttrAccessGroup] = accessGroup }
      var found: CFTypeRef?
      let status = SecItemCopyMatching(query as CFDictionary, &found)
      guard status == errSecSuccess, let refs = found as? [SecKey] else {
        throw SignetError.system("SecItemCopyMatching", status)
      }
      guard
        let key = refs.first(where: {
          SecKeyCopyPublicKey($0).flatMap { SecKeyCopyExternalRepresentation($0, nil) as Data? } == publicKey
        })
      else { throw SignetError.system("SecItemCopyMatching", errSecItemNotFound) }

      var error: Unmanaged<CFError>?
      guard let der = SecKeyCreateSignature(key, .ecdsaSignatureDigestX962, digest as CFData, &error) as Data? else {
        approval = nil
        throw error!.takeRetainedValue() as Error
      }
      return try P256.Signing.ECDSASignature(derRepresentation: der).rawRepresentation
    }
  }
#endif
