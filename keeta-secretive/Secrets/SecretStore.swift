import Foundation

protocol SecretStore: ObservableObject, Identifiable {
    /// A unique identifier for the store.
//    var id: UUID { get }
    /// A user-facing name for the store.
//    var name: String { get }
    /// The secrets the store manages.
    var secrets: [Secret] { get }

    /// Signs a data payload with a specified Secret.
    /// - Parameters:
    ///   - data: The data to sign.
    ///   - secret: The ``Secret`` to sign with.
    ///   - provenance: A ``SigningRequestProvenance`` describing where the request came from.
    ///   - raw: Wheither the data to sign should be hashed again
    /// - Returns: The signed data.
    func sign(data: Data, with secret: Secret, for processName: String, isRaw: Bool) throws -> Data

    /// Checks to see if there is currently a valid persisted authentication for a given secret.
    /// - Parameters:
    ///   - secret: The ``Secret`` to check if there is a persisted authentication for.
    /// - Returns: A persisted authentication context, if a valid one exists.
//    func existingPersistedAuthenticationContext(secret: Secret) -> PersistedAuthenticationContext?

    /// Persists user authorization for access to a secret.
    /// - Parameters:
    ///   - secret: The ``Secret`` to persist the authorization for.
    ///   - duration: The duration that the authorization should persist for.
    ///  - Note: This is used for temporarily unlocking access to a secret which would otherwise require authentication every single use. This is useful for situations where the user anticipates several rapid accesses to a authorization-guarded secret.
//    func persistAuthentication(secret: Secret, forDuration duration: TimeInterval) throws
}
