import Foundation

/// Where Signet keeps its socket and files, the same for the standalone app, Workspace for Mac and
/// the `workspace` CLI (spec 141 CG-126).
public enum SignetPaths {
  /// Signet's own folder: `~/Library/Signet`.
  public static func folder(home: String = NSHomeDirectory()) -> String { home + "/Library/Signet" }

  /// The socket git and SSH are pointed at, served by whichever Signet runs.
  public static func socket(home: String = NSHomeDirectory()) -> String { folder(home: home) + "/agent.sock" }

  /// Where Keeta Agent served its key, kept leading to `socket` so setups made before still work.
  public static func keetaAgentSocket(home: String = NSHomeDirectory()) -> String {
    home + "/Library/KeetaAgent/Data/socket.ssh"
  }
}
