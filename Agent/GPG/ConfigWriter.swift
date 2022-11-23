import Foundation

final class ConfigWriter {
    
    private static let fileManager = FileManager.default
    private static let newLine = "\n"
    
    static func add(_ config: Config) throws {
        print("** Attempt to write config \(config)")
        
        let filePath = (config.isSystem ? NSHomeDirectory() : configPath) + "/\(config.filename)"
        
        let text = config.payload + newLine
        
        let writeNewFile: () -> Void = {
            print("** Write new config \(config)")
            fileManager.createFile(atPath: filePath, contents: text.data(using: .utf8)!)
        }
        
        guard fileManager.fileExists(atPath: filePath) && config.isSystem else {
            writeNewFile()
            return
        }
        
        let handle = try FileHandle(forUpdating: URL(fileURLWithPath: filePath))
        
        let existing = try handle.readToEnd() ?? .init()
        let existingString = String(data: existing, encoding: .utf8) ?? ""
        
        guard !existingString.isEmpty else {
            writeNewFile()
            return
        }
        
        guard !existingString.contains(config.payload) else { return }
        
        try handle.seekToEnd()
        
        print("** Append config \(config)")
        
        let data = (existingString.hasSuffix(newLine) ? text : "\(newLine)\(text)").data(using: .utf8)!
        try handle.write(contentsOf: data)
    }
}
