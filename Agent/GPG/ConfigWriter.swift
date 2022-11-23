import Foundation

final class ConfigWriter {
    
    static func add(_ config: Config) throws {
        print("** Attempt to write config \(config)")
        
        let fileManager = FileManager.default
        let filePath = configPath + "/\(config.filename)"
        
        if !fileManager.fileExists(atPath: filePath) {
            print("** Write new config \(config)")
            
            let text = config.payload + "\n"
            fileManager.createFile(atPath: filePath, contents: text.data(using: .utf8)!)
        }
    }
}
