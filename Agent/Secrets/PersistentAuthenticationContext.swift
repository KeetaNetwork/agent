import Foundation
import LocalAuthentication

protocol PersistedAuthenticationContext {
    var valid: Bool { get }
    var expiration: Date { get }
}

struct PersistentAuthenticationContext: PersistedAuthenticationContext {

    let secret: SecureEnclaveSecret
    let context: LAContext
    /// - Note -  Monotonic time instead of Date() to prevent people setting the clock back.
    let monotonicExpiration: UInt64

    init(secret: SecureEnclaveSecret, context: LAContext, duration: TimeInterval) {
        self.secret = secret
        self.context = context
        let durationInNanoSeconds = Measurement(value: duration, unit: UnitDuration.seconds).converted(to: .nanoseconds).value
        self.monotonicExpiration = clock_gettime_nsec_np(CLOCK_MONOTONIC) + UInt64(durationInNanoSeconds)
    }

    var valid: Bool {
        clock_gettime_nsec_np(CLOCK_MONOTONIC) < monotonicExpiration
    }

    var expiration: Date {
        let remainingNanoseconds = monotonicExpiration - clock_gettime_nsec_np(CLOCK_MONOTONIC)
        let remainingInSeconds = Measurement(value: Double(remainingNanoseconds), unit: UnitDuration.nanoseconds).converted(to: .seconds).value
        return Date(timeIntervalSinceNow: remainingInSeconds)
    }
}
