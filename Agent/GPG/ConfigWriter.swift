import Foundation

final class ConfigWriter {

    static let configDirectory = "\(NSHomeDirectory())"
    
    private static let fileManager = FileManager.default
    private static let newLine = "\n"
    
    static func add(_ config: Config) throws {
        var filePath = configDirectory
        
        try createDirectoryIfNeeded(for: config.folderPath, filePath: &filePath)
        
        filePath.append("/\(config.filename)")
        
        let text = config.payload + newLine
        
        guard fileManager.fileExists(atPath: filePath) else {
            fileManager.createFile(atPath: filePath, contents: text.data(using: .utf8)!)
            return
        }
        
        let handle = try FileHandle(forUpdating: URL(fileURLWithPath: filePath))
        
        let existing = try handle.readToEnd() ?? .init()
        let existingString = String(data: existing, encoding: .utf8) ?? ""
        
        guard !existingString.contains(config.payload) else { return }
        
        if config.isSystem {
            try handle.seekToEnd()
            
            let data = (existingString.hasSuffix(newLine) ? text : "\(newLine)\(text)").data(using: .utf8)!
            try handle.write(contentsOf: data)
        }
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
