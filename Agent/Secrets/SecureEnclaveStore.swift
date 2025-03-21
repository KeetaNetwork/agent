import Foundation
import Security
import LocalAuthentication

class SecureEnclaveStore: SecretStore {
    
    @Published public private(set) var secrets: [Secret] = []
    
    private let keyTag = "com.keeta.agent.key".data(using: .utf8)! as CFData
    private let keyType = kSecAttrKeyTypeECSECPrimeRandom
    private let authenticationReuseDuration: TimeInterval = 3
    private var persistedAuthenticationContexts: [Secret.ID: PersistentAuthenticationContext] = [:]
    
    func setup() {
        loadSecrets()
    }
    
    func createKeyPairIfNeeded(with name: String) throws {
        if !secrets.contains(where: { $0.name == name }) {
            try create(name: name)
        }
    }
    
    private func create(name: String) throws {
        var accessError: SecurityError?
        let flags: SecAccessControlCreateFlags = [.privateKeyUsage, .userPresence]
        let access =
            SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                            flags,
                                            &accessError) as Any
        if let error = accessError {
            throw error.takeRetainedValue() as Error
        }

        let attributes = [
            kSecAttrLabel: name,
            kSecAttrKeyType: keyType,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecAttrApplicationTag: keyTag,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrAccessControl: access
            ]
        ] as CFDictionary

        var createKeyError: SecurityError?
        let keypair = SecKeyCreateRandomKey(attributes, &createKeyError)
        if let error = createKeyError {
            throw error.takeRetainedValue() as Error
        }
        guard let keypair = keypair, let publicKey = SecKeyCopyPublicKey(keypair) else {
            throw KeychainError(statusCode: nil)
        }
        try savePublicKey(publicKey, name: name)
        reloadSecrets()
    }
    
    func sign(data: Data, with secret: Secret, for applicationName: String?, isRaw: Bool) throws -> Data {
        let context: LAContext
        if let existing = persistedAuthenticationContexts[secret.id], existing.valid {
            context = existing.context
        } else {
            let newContext = LAContext()
            newContext.localizedCancelTitle = "Deny"
            newContext.touchIDAuthenticationAllowableReuseDuration = authenticationReuseDuration
            context = newContext
            let secret = secret as! SecureEnclaveSecret
            persistedAuthenticationContexts[secret.id] = .init(secret: secret, context: newContext, duration: 5)
        }
        if let processName = applicationName {
            context.localizedReason = "sign a request from \"\(processName)\" using secret \"\(secret.name)\""
        } else {
            context.localizedReason = "sign a request using secret \"\(secret.name)\""
        }
        
        let attributes = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrKeyType: keyType,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecAttrApplicationTag: keyTag,
            kSecUseAuthenticationContext: context,
            kSecReturnRef: true
            ] as CFDictionary
        var untyped: CFTypeRef?
        let status = SecItemCopyMatching(attributes, &untyped)
        if status != errSecSuccess {
            throw KeychainError(statusCode: status)
        }
        guard let untypedSafe = untyped else {
            throw KeychainError(statusCode: errSecSuccess)
        }
        let key = untypedSafe as! SecKey
        var signError: SecurityError?
        
        let algorithm: SecKeyAlgorithm = isRaw ? .ecdsaSignatureDigestX962 : .ecdsaSignatureMessageX962SHA256
        
        guard let signature = SecKeyCreateSignature(key, algorithm, data as CFData, &signError) else {
            throw SigningError(error: signError)
        }
        return signature as Data
    }
    
    // MARK: Helper
    
    private func savePublicKey(_ publicKey: SecKey, name: String) throws {
        let attributes = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: keyType,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrApplicationTag: keyTag,
            kSecValueRef: publicKey,
            kSecAttrIsPermanent: true,
            kSecReturnData: true,
            kSecAttrLabel: name
            ] as CFDictionary
        let status = SecItemAdd(attributes, nil)
        if status != errSecSuccess {
            throw KeychainError(statusCode: status)
        }
    }
    
    private func reloadSecrets(notifyAgent: Bool = true) {
        secrets.removeAll()
        loadSecrets()
    }
    
    private func loadSecrets() {
        let publicAttributes = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: keyType,
            kSecAttrApplicationTag: keyTag,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecReturnRef: true,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnAttributes: true
            ] as CFDictionary
        var publicUntyped: CFTypeRef?
        SecItemCopyMatching(publicAttributes, &publicUntyped)
        guard let publicTyped = publicUntyped as? [[CFString: Any]] else { return }
        let privateAttributes = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: keyType,
            kSecAttrApplicationTag: keyTag,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecReturnRef: true,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnAttributes: true
            ] as CFDictionary
        var privateUntyped: CFTypeRef?
        SecItemCopyMatching(privateAttributes, &privateUntyped)
        guard let privateTyped = privateUntyped as? [[CFString: Any]] else { return }
        let privateMapped = privateTyped.reduce(into: [:] as [Data: [CFString: Any]]) { partialResult, next in
            let id = next[kSecAttrApplicationLabel] as! Data
            partialResult[id] = next
        }

        let wrapped: [Secret] = publicTyped.map {
            let name = $0[kSecAttrLabel] as? String ?? "Unnamed"
            let id = $0[kSecAttrApplicationLabel] as! Data
            let publicKeyRef = $0[kSecValueRef] as! SecKey
            let publicKeyAttributes = SecKeyCopyAttributes(publicKeyRef) as! [CFString: Any]
            let publicKey = publicKeyAttributes[kSecValueData] as! Data
            return SecureEnclaveSecret(id: id.base64EncodedString(), name: name, publicKey: publicKey)
        }
        secrets.append(contentsOf: wrapped)
    }
}

typealias SecurityError = Unmanaged<CFError>

struct KeychainError: Error {
    let statusCode: OSStatus?
}

struct SigningError: Error {
    let error: SecurityError?
}
