import Foundation

final class ConfigWriter {
    
    private static let fileManager = FileManager.default
    private static let newLine = "\n"
    
    static func add(_ config: Config) throws {
        let filePath = configPath + "/\(config.filename)"
        
        let text = config.payload + newLine
        
        guard fileManager.fileExists(atPath: filePath) && config.isSystem else {
            fileManager.createFile(atPath: filePath, contents: text.data(using: .utf8)!)
            return
        }
        
        let handle = try FileHandle(forUpdating: URL(fileURLWithPath: filePath))
        
        let existing = try handle.readToEnd() ?? .init()
        let existingString = String(data: existing, encoding: .utf8) ?? ""
        
        guard !existingString.contains(config.payload) else { return }
        
        try handle.seekToEnd()
        
        let data = (existingString.hasSuffix(newLine) ? text : "\(newLine)\(text)").data(using: .utf8)!
        try handle.write(contentsOf: data)
    }
}
