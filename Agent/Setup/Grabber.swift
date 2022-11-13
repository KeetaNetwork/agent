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
        let range = NSRange(location: 0, length: output.utf16.count)
        let length = 40
        do {
            // TODO: do it properly!
            let regex = try NSRegularExpression(pattern: "[A-Z0-9]{\(length)}\\.rev")//
            guard let match = regex.firstMatch(in: output, range: range) else { return nil }
            return String(output[Range(match.range, in: output)!].dropLast(4))
        } catch {
            return nil
        }
    }
    
    static func hasBadSignatures(from output: String) -> Bool {
        output.contains("bad signature")
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
