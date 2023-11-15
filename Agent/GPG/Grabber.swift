import Foundation

final class Grabber {
    
    private static let keyIdLength = 16
    
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
    
    struct KeyInformation: Hashable, Equatable {
        let email: String
        let name: String
        let keyId: String
    }
    
    // Only works if there exists exactly one key!
    static func keyInformation(from output: String, in keyBoxDirectory: String, keyCurve: String) -> KeyInformation? {
        let kbxPath = "\(keyBoxDirectory)/pubring.kbx"
        
        var keysOutput = [String]()
        let keyNumberOfLines = 5
        var currentKeyOutput = ""
        var currentLine: Int?
        
        let appendCurrentKeyOutput = {
            keysOutput.append(currentKeyOutput)
            currentKeyOutput.removeAll()
            currentLine = nil
        }
        
        output.enumerateLines { line, stop in
            if line.contains(kbxPath) {
                if currentLine != nil {
                    // ⛔️ current key output not completed yet ⛔️
                    appendCurrentKeyOutput()
                }
                currentKeyOutput.append(line)
                currentLine = 1
            } else if currentLine != nil {
                if currentLine! < keyNumberOfLines {
                    currentKeyOutput.append("\n" + line)
                    currentLine! += 1
                } else {
                    appendCurrentKeyOutput()
                }
            }
        }
        
        if currentLine == keyNumberOfLines {
            keysOutput.append(currentKeyOutput)
        }
        
        var extractedInfos = Set<KeyInformation>()
        
        guard let nameRegex = try? NSRegularExpression(pattern: "\\[ultimate\\] (.+?) <.*?>"),
              let emailRegex = try? NSRegularExpression(pattern: "<(.*?)>") else {
            return nil
        }
        
        for keyOutput in keysOutput {
            if let name = extract(regex: nameRegex, from: keyOutput).first,
               let email = extract(regex: emailRegex, from: keyOutput).first,
               // TODO: use regex to extract KeyID
               let keyId = shortKeyId(from: keyOutput, for: email, keyCurve: keyCurve) {
                extractedInfos.insert(.init(email: email, name: name, keyId: keyId))
            }
        }
        
        guard let keyInfo = extractedInfos.first,
              extractedInfos.count == 1 else {
            return nil
        }
        
        return keyInfo
    }
    
    static func shortKeyId(from output: String, for email: String, keyCurve: String) -> String? {
        let startPrefix = "pub"
        
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
        
        let keyCurvePrefix = "\(keyCurve)/"
        guard key.hasPrefix(keyCurvePrefix) else  { return nil }
        
        key = key.replacingOccurrences(of: keyCurvePrefix, with: "")
        return key.count >= keyIdLength ? String(key.prefix(keyIdLength)) : nil
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
    
    // MARK: - Helper
    
    private static func extract(regex: NSRegularExpression, from input: String) -> [String] {
        let matches = regex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        
        return matches.compactMap {
            let rangeIndex = $0.numberOfRanges > 1 ? 1 : 0
            if let range = Range($0.range(at: rangeIndex), in: input), !range.isEmpty {
                return String(input[range])
            } else {
                return nil
            }
        }
    }
}
