import Foundation

struct SigningRequestProvenance: Equatable {
    
    /// A list of processes involved in the request.
    /// - Note: A chain will typically consist of many elements even for a simple request. For example, running `git fetch` in Terminal.app would generate a request chain of `ssh` -> `git` -> `zsh` -> `login` -> `Terminal.app`
    var chain: [Process]
    
    init(root: Process) {
        self.chain = [root]
    }

    /// The `Process` which initiated the signing request.
    var origin: Process {
        chain.last!
    }
}

extension SigningRequestProvenance {
    
    /// Describes a process in a `SigningRequestProvenance` chain.
    struct Process: Equatable {
        
        /// The pid of the process.
        let pid: Int32
        /// A user-facing name for the process.
        let processName: String
        /// A user-facing name for the application, if one exists.
        let appName: String?
        /// An icon representation of the application, if one exists.
        let iconURL: URL?
        /// The pid of the process's parent.
        let parentPID: Int32?
        
        var displayName: String {
            appName ?? processName
        }
    }
    
}
