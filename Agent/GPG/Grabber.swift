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
    
    static func shortKeyId(from output: String, for email: String, keyCurve: String) -> String? {
        let startPrefix = "pub"
        let length = 16
        
        let lines = output.split(whereSeparator: \.isNewline)
        
        guard let keyIndex = lines.indices.firstIndex(where: { index in
            let emailIndex = index + 2
            return lines[index].hasPrefix(startPrefix)
                && lines.indices.contains(emailIndex)
                && lines[emailIndex].contains(email)
        }) else { return nil }
        
        var key = String(lines[keyIndex])
        key = key.replacingOccurrences(of: startPrefix, with: "")
        key = key.trimmingCharacters(in: .whitespaces)
        key = key.replacingOccurrences(of: "\(keyCurve)/", with: "")
        
        return key.count >= length ? String(key.prefix(length)) : nil
    }
    
    static func hasBadSignatures(from output: String) -> Bool {
        output.contains("bad signature")
    }
    
    static func gpgKey(from output: String) -> String? {
        let start = GPGKey.header
        let end = GPGKey.footer
        
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
