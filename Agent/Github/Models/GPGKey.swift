import Foundation

struct GPGKey: Codable {
    let id: String
    let value: String
    let fullName: String
    let email: String
    
    var displayValue: String {
        let start = "-----BEGIN PGP PUBLIC KEY BLOCK-----"
        let end = "-----END PGP PUBLIC KEY BLOCK-----"
        let newLine = "\n"
        
        var displayValue = value
        displayValue = displayValue.replacingOccurrences(of: start, with: "")
        displayValue = displayValue.replacingOccurrences(of: end, with: "")
        displayValue = displayValue.trimmingCharacters(in: .whitespacesAndNewlines)
        displayValue = displayValue.replacingOccurrences(of: newLine, with: "\\n")
        
        return [start, displayValue, end].joined(separator: newLine)
    }
}
