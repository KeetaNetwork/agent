import Foundation

final class CommandExecutor {
    
    struct Output {
        private let command: Command
        let value: String
        
        init(command: Command, value: String) {
            self.command = command
            self.value = value
        }
        
        private var name: String { String(describing: command) }
        
        func expectIsEmpty() throws {
            if !value.isEmpty {
                throw NSError(domain: "Output for command: '\(name)' isn't empty!", code: 500)
            }
        }
        
        func grap(_ grabber: (String) -> String?) throws -> String {
            guard let result = grabber(value) else {
                throw NSError(domain: "Empty result for command: '\(name)'", code: 500)
            }
            return result
        }
        
        func expectFalse(_ grabber: (String) -> Bool) throws {
            if grabber(value) {
                throw NSError(domain: "Empty result for command: '\(name)'", code: 500)
            }
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
                task.executableURL = executableURL
                
                var env = ProcessInfo.processInfo.environment
                env["SSH_AUTH_SOCK"] = socketPath
                task.environment = env
                
                print("** Run command \(command)")
                try task.run()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                print("** Output\n\(output)")
                continuation.resume(returning: Output(command: command, value: output))
            } catch let error {
                print(error)
                continuation.resume(throwing: error)
            }
        }
    }
}
