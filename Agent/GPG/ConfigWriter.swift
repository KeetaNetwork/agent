import Foundation

final class ConfigWriter {

    static let configDirectory = "\(NSHomeDirectory())"
    
    private static let fileManager = FileManager.default
    
    static func add(_ config: Config) throws {
        var filePath = configDirectory
        
        try createDirectoryIfNeeded(for: config.folderPath, filePath: &filePath)
        
        let fileURL = URL(fileURLWithPath: filePath.appending("/\(config.filename)"))
        
        let text = config.payload + "\n"
        
        let write: (Data) -> Void = {
            fileManager.createFile(atPath: fileURL.path, contents: $0)
        }
        
        guard let existing = fileManager.contents(atPath: fileURL.path), !existing.isEmpty else {
            write(text.data(using: .utf8)!)
            return
        }
        
        guard let existingString = String(data: existing, encoding: .utf8), !existingString.isEmpty else {
            throw NSError(domain: "Unknown config file content at '\(filePath)'", code: 500)
        }
        
        guard !existingString.contains(config.payload) else { return }
        
        var existingLines = existingString.split(whereSeparator: \.isNewline)
        
        if let indexToReplace = existingLines.firstIndex(where: { $0.hasPrefix(config.linePrefixToReplace) }) {
            existingLines.remove(at: indexToReplace)
        }
        
        let startWithNewLine = existingString.isEmpty
        let data = existingLines.joined(separator: "\n").appending("\(startWithNewLine ? "\n" : "")\(text)").data(using: .utf8)!
        write(data)
    }
    
    private static func createDirectoryIfNeeded(for folderPath: String?, filePath: inout String) throws {
        guard let directory = folderPath else { return }
        
        filePath.append("/\(directory)")
        
        if !fileManager.fileExists(atPath: filePath) {
            try fileManager.createDirectory(
                at: .init(fileURLWithPath: filePath),
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 448]
            )
        }
    }
}
