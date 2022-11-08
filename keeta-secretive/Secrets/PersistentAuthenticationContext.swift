import Foundation
import LocalAuthentication

protocol PersistedAuthenticationContext {
    /// Whether the context remains valid.
    var valid: Bool { get }
    /// The date at which the authorization expires and the context becomes invalid.
    var expiration: Date { get }
}

struct PersistentAuthenticationContext: PersistedAuthenticationContext {

    /// The Secret to persist authentication for.
    let secret: SecureEnclaveSecret
    /// The LAContext used to authorize the persistent context.
    let context: LAContext
    /// An expiration date for the context.
    /// - Note -  Monotonic time instead of Date() to prevent people setting the clock back.
    let monotonicExpiration: UInt64

    /// Initializes a context.
    /// - Parameters:
    ///   - secret: The Secret to persist authentication for.
    ///   - context: The LAContext used to authorize the persistent context.
    ///   - duration: The duration of the authorization context, in seconds.
    init(secret: SecureEnclaveSecret, context: LAContext, duration: TimeInterval) {
        self.secret = secret
        self.context = context
        let durationInNanoSeconds = Measurement(value: duration, unit: UnitDuration.seconds).converted(to: .nanoseconds).value
        self.monotonicExpiration = clock_gettime_nsec_np(CLOCK_MONOTONIC) + UInt64(durationInNanoSeconds)
    }

    /// A boolean describing whether or not the context is still valid.
    var valid: Bool {
        clock_gettime_nsec_np(CLOCK_MONOTONIC) < monotonicExpiration
    }

    var expiration: Date {
        let remainingNanoseconds = monotonicExpiration - clock_gettime_nsec_np(CLOCK_MONOTONIC)
        let remainingInSeconds = Measurement(value: Double(remainingNanoseconds), unit: UnitDuration.nanoseconds).converted(to: .seconds).value
        return Date(timeIntervalSinceNow: remainingInSeconds)
    }
}
