import Foundation

final class Grabber {
    
    static func keyGrip(from output: String) -> String? {
        let key = "KEY-FRIEDNLY"
        let length = 40
        let lines = output.split(whereSeparator: \.isNewline)
        
        guard let index = lines.firstIndex(where: { $0.contains(key) }) else {
            return nil
        }
        var line = String(lines[index])
        guard let keyRange = line.range(of: key) else { return nil }
        
        line.removeSubrange(line.startIndex..<keyRange.upperBound)
        guard line.count > length else { return nil }
        line = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(line.prefix(length))
    }
    
    static func keyId(from output: String) -> String? {
        let lines = output.split(whereSeparator: \.isNewline)
        let length = 40
        
        guard let startIndex = lines.firstIndex(where: { $0.hasPrefix("pub ") }),
              let endIndex = lines.firstIndex(where: { $0.hasPrefix("uid ") }),
                endIndex > startIndex else { return nil }
        let result = lines[startIndex + 1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // TODO: verify email
//        lines[endIndex].contains("email")
        
        return result.count == length ? result : nil
    }
    
    static func gpgKey(from output: String) -> String? {
        let start = "-----BEGIN PGP PUBLIC KEY BLOCK-----"
        let end = "-----END PGP PUBLIC KEY BLOCK-----"
        
        let hasPrefix = output.hasPrefix(start)
        let hasSuffix = output.hasSuffix(end)
        if hasPrefix && hasSuffix {
            return output
        }
        
        guard let prefixRange = output.range(of: start),
                let suffixRange = output.range(of: end) else {
            return nil
        }
        
        var result = output
        
        if suffixRange.upperBound < result.endIndex {
            result.removeSubrange(suffixRange.upperBound..<result.endIndex)
        }
        
        if prefixRange.upperBound > result.startIndex {
            result.removeSubrange(result.startIndex..<prefixRange.lowerBound)
        }
        
        return result
    }
}
