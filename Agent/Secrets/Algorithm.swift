import Foundation

enum Algorithm: Hashable {

    case ellipticCurve

    /// Initializes the Algorithm with a secAttr representation of an algorithm.
    init(secAttr: NSNumber) {
        let secAttrString = secAttr.stringValue as CFString
        switch secAttrString {
        case kSecAttrKeyTypeEC:
            self = .ellipticCurve
        default:
            fatalError("Unknown key algorithm: \(secAttr)")
        }
    }
}
