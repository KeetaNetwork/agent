import Foundation

final class CommandExecutor {
    
    struct Output {
        private let command: Command
        let value: String
        
        init(command: Command, value: String) {
            self.command = command
            self.value = value
        }
        
        func expectIsEmpty() throws {
            if !value.isEmpty {
                let name = String(describing: command)
                throw NSError(domain: "Output for command: '\(name)' isn't empty!", code: 500)
            }
        }
        
        func grap(_ grabber: (String) -> String?) throws -> String {
            guard let result = grabber(value) else {
                let name = String(describing: command)
                throw NSError(domain: "Empty result for command: '\(name)'", code: 500)
            }
            return result
        }
    }
    
    @discardableResult
    static func execute(_ command: Command) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let executableURL = URL(fileURLWithPath: command.executable)
                
                let task = Process()
                let pipe = Pipe()
                
                task.standardOutput = pipe
                task.standardError = pipe
                task.arguments = command.commands
    //            task.launchPath = "/bin/zsh"
                task.executableURL = executableURL
                task.standardInput = nil
                
                try task.run()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                #if DEBUG
                print(output)
                #endif
                continuation.resume(returning: Output(command: command, value: output))
            } catch let error {
                print(error)
                continuation.resume(throwing: error)
            }
        }
    }
}
