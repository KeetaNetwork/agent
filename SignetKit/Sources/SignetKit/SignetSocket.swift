import Dispatch
import Foundation

#if canImport(Glibc)
  import Glibc
#elseif canImport(Darwin)
  import Darwin
#endif

/// Signet's SSH agent on a Unix socket, served by whichever Signet runs (signet-update-brief.md
/// step 3): `start()` serves the socket when nothing answers there and stands by when another
/// Signet does, `watch(every:)` takes over once that one quits, and `stop()` releases the socket.
/// So the standalone app and Workspace for Mac can be installed side by side.
public final class SignetSocket: @unchecked Sendable {
  public enum State: Sendable, Equatable {
    case stopped
    /// This Signet answers on the socket.
    case serving
    /// Another Signet answers on the socket; this one waits.
    case standingBy
  }

  public let path: String
  private let agent: SSHAgent
  private let lock = NSLock()
  private var listener: Int32 = -1
  private var bound: (dev: UInt64, ino: UInt64)?
  private var running: SocketLoop?
  private var watcher: DispatchSourceTimer?
  private var _state = State.stopped
  private var _onChange: (@Sendable (State) -> Void)?
  private let notifications = DispatchQueue(label: "signet.socket.state")

  public init(path: String, agent: SSHAgent) {
    self.path = path
    self.agent = agent
  }

  deinit { stop() }

  public var state: State { lock.withLock { _state } }

  /// Called on a background queue whenever `state` changes.
  public var onChange: (@Sendable (State) -> Void)? {
    get { lock.withLock { _onChange } }
    set { lock.withLock { _onChange = newValue } }
  }

  /// Serves the socket unless another Signet answers there, in which case this one stands by.
  /// Calling it again while standing by takes over if the other has gone.
  @discardableResult
  public func start() throws -> State {
    lock.lock()
    if _state == .serving {
      lock.unlock()
      return .serving
    }
    lock.unlock()

    try Self.makeFolder(for: path)
    // Two Signets starting together must not both clear the path and bind it.
    let claim = open(path + ".lock", O_CREAT | O_RDWR, 0o600)
    guard claim >= 0 else { throw SignetError.system("open", errno) }
    defer { close(claim) }
    flock(claim, LOCK_EX)
    defer { flock(claim, LOCK_UN) }

    if Self.answers(at: path) { return set(.standingBy) }

    var st = stat()
    if lstat(path, &st) == 0 {
      let kind = st.st_mode & S_IFMT
      guard kind == S_IFSOCK || kind == S_IFLNK else { throw SignetError.system("replace \(path)", EEXIST) }
      unlink(path)
    }
    let fd = try Self.socketFD()
    do {
      try Self.withAddress(path) { addr, len in
        guard bind(fd, addr, len) == 0 else { throw SignetError.system("bind", errno) }
      }
      chmod(path, 0o600)
      guard listen(fd, 16) == 0 else { throw SignetError.system("listen", errno) }
    } catch {
      close(fd)
      throw error
    }
    guard stat(path, &st) == 0 else { close(fd); throw SignetError.system("stat", errno) }

    let loop = SocketLoop(listener: fd, agent: agent)
    lock.withLock {
      listener = fd
      bound = (UInt64(st.st_dev), UInt64(st.st_ino))
      running = loop
    }
    loop.start()
    return set(.serving)
  }

  /// While standing by, checks every `interval` seconds whether the socket is free, and serves it
  /// once it is.
  public func watch(every interval: TimeInterval) {
    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "signet.socket.watch"))
    timer.schedule(deadline: .now() + interval, repeating: interval)
    timer.setEventHandler { [weak self] in
      guard let self, self.state == .standingBy else { return }
      _ = try? self.start()
    }
    lock.withLock {
      watcher?.cancel()
      watcher = timer
    }
    timer.resume()
  }

  /// Stops serving or standing by, and removes the socket if it is still this Signet's.
  public func stop() {
    lock.lock()
    let loop = running, fd = listener, mine = bound, timer = watcher
    running = nil
    listener = -1
    bound = nil
    watcher = nil
    lock.unlock()
    timer?.cancel()
    loop?.stop()
    if fd >= 0 {
      var st = stat()
      if let mine, stat(path, &st) == 0, UInt64(st.st_dev) == mine.dev, UInt64(st.st_ino) == mine.ino {
        unlink(path)
      }
      close(fd)
    }
    if state != .stopped { set(.stopped) }
  }

  /// Makes `legacy` (Keeta Agent's socket path) lead to this socket, unless a Keeta Agent that
  /// hasn't been updated still serves its own key there.
  public func link(from legacy: String) throws {
    var st = stat()
    if lstat(legacy, &st) == 0 {
      let kind = st.st_mode & S_IFMT
      if kind == S_IFLNK, (try? FileManager.default.destinationOfSymbolicLink(atPath: legacy)) == path { return }
      if kind == S_IFSOCK, Self.answers(at: legacy) { return }
      guard kind == S_IFSOCK || kind == S_IFLNK else { throw SignetError.system("replace \(legacy)", EEXIST) }
      unlink(legacy)
    } else {
      try Self.makeFolder(for: legacy)
    }
    guard symlink(path, legacy) == 0 else { throw SignetError.system("symlink", errno) }
  }

  /// Whether an SSH agent answers on the socket at `path`. One that accepts but is slow to answer
  /// counts as answering, so a busy Signet is never replaced.
  public static func answers(at path: String) -> Bool {
    guard let fd = try? socketFD() else { return false }
    defer { close(fd) }
    let connected = (try? withAddress(path) { addr, len in connect(fd, addr, len) == 0 }) ?? false
    guard connected else { return false }
    let request = SSHWire.string(Data([SSHAgent.Message.requestIdentities.rawValue]))
    guard SocketLoop.send(fd, request) else { return false }
    var p = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
    guard poll(&p, 1, 2000) > 0 else { return true }
    var head = [UInt8](repeating: 0, count: 5)
    return recv(fd, &head, 5, 0) == 5 && head[4] == SSHAgent.Message.identitiesAnswer.rawValue
  }

  // MARK: -

  @discardableResult
  private func set(_ s: State) -> State {
    let notify: (@Sendable (State) -> Void)? = lock.withLock {
      guard _state != s else { return nil }
      _state = s
      return _onChange
    }
    if let notify { notifications.async { notify(s) } }
    return s
  }

  private static func makeFolder(for path: String) throws {
    let folder = (path as NSString).deletingLastPathComponent
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: folder, isDirectory: &isDir) { return }
    try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
    chmod(folder, 0o700)
  }

  static func socketFD() throws -> Int32 {
    #if canImport(Glibc)
      let fd = socket(AF_UNIX, Int32(SOCK_STREAM.rawValue), 0)
    #else
      let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    #endif
    guard fd >= 0 else { throw SignetError.system("socket", errno) }
    closeOnExec(fd)
    #if canImport(Darwin)
      var on: Int32 = 1
      setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
    #endif
    return fd
  }

  static func withAddress<R>(_ path: String, _ body: (UnsafePointer<sockaddr>, socklen_t) throws -> R) throws -> R {
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)
    let bytes = Array(path.utf8)
    guard bytes.count < MemoryLayout.size(ofValue: addr.sun_path) else { throw SignetError.pathTooLong(path) }
    withUnsafeMutableBytes(of: &addr.sun_path) { buf in
      for (i, b) in bytes.enumerated() { buf[i] = b }
    }
    #if canImport(Darwin)
      addr.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
    #endif
    return try withUnsafePointer(to: &addr) {
      try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        try body($0, socklen_t(MemoryLayout<sockaddr_un>.size))
      }
    }
  }
}

/// Accepts connections on a listening socket until stopped, answering each on its own thread, so a
/// request waiting on Touch ID holds up no other.
final class SocketLoop: @unchecked Sendable {
  private let listener: Int32
  private let agent: SSHAgent
  private let lock = NSLock()
  private var stopped = false
  private let done = DispatchSemaphore(value: 0)

  /// Requests larger than this are refused; ssh-agent's own limit is 256 KiB.
  static let maxRequest = 256 * 1024

  init(listener: Int32, agent: SSHAgent) {
    self.listener = listener
    self.agent = agent
  }

  func start() {
    let t = Thread { [self] in
      while !lock.withLock({ stopped }) {
        var p = pollfd(fd: listener, events: Int16(POLLIN), revents: 0)
        guard poll(&p, 1, 100) > 0 else { continue }
        let c = accept(listener, nil, nil)
        guard c >= 0 else { continue }
        closeOnExec(c)
        #if canImport(Darwin)
          var on: Int32 = 1
          setsockopt(c, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
        #endif
        // A thread of its own, not a global queue: on macOS, GCD adds no thread to a global
        // queue while the process's other threads look busy (Swift concurrency's, blocked on
        // I/O), and the request would wait, unanswered, behind them.
        let connection = Thread { [agent] in Self.serve(c, agent: agent) }
        connection.name = "signet.connection"
        connection.start()
      }
      done.signal()
    }
    t.name = "signet.socket"
    t.start()
  }

  func stop() {
    let wasRunning = lock.withLock {
      defer { stopped = true }
      return !stopped
    }
    if wasRunning { done.wait() }
  }

  private static func serve(_ c: Int32, agent: SSHAgent) {
    defer { close(c) }
    let peer = peerPID(c)
    while let head = read(c, 4) {
      let length = head.reduce(0) { $0 << 8 | Int($1) }
      guard length > 0, length <= maxRequest, let payload = read(c, length) else { return }
      guard send(c, SSHWire.string(agent.respond(to: payload, peer: peer))) else { return }
    }
  }

  private static func read(_ fd: Int32, _ n: Int) -> Data? {
    var out = Data(capacity: n)
    var buf = [UInt8](repeating: 0, count: min(n, 65536))
    while out.count < n {
      let got = recv(fd, &buf, min(buf.count, n - out.count), 0)
      if got < 0, errno == EINTR { continue }
      guard got > 0 else { return nil }
      out.append(contentsOf: buf[0..<got])
    }
    return out
  }

  static func send(_ fd: Int32, _ data: Data) -> Bool {
    #if canImport(Glibc)
      let flags = Int32(MSG_NOSIGNAL)
    #else
      let flags: Int32 = 0
    #endif
    var sent = 0
    return data.withUnsafeBytes { buf in
      while sent < data.count {
        let n = Glibc_or_Darwin_send(fd, buf.baseAddress! + sent, data.count - sent, flags)
        if n < 0, errno == EINTR { continue }
        guard n > 0 else { return false }
        sent += n
      }
      return true
    }
  }

  private static func peerPID(_ fd: Int32) -> Int32? {
    #if canImport(Darwin)
      var pid: pid_t = 0
      var len = socklen_t(MemoryLayout<pid_t>.size)
      return getsockopt(fd, SOL_LOCAL, LOCAL_PEERPID, &pid, &len) == 0 ? pid : nil
    #else
      // struct ucred { pid_t pid; uid_t uid; gid_t gid; }, which Glibc's module hides.
      var cred: (Int32, UInt32, UInt32) = (0, 0, 0)
      var len = socklen_t(MemoryLayout.size(ofValue: cred))
      return getsockopt(fd, SOL_SOCKET, SO_PEERCRED, &cred, &len) == 0 ? cred.0 : nil
    #endif
  }
}

@inline(__always)
private func Glibc_or_Darwin_send(_ fd: Int32, _ p: UnsafeRawPointer, _ n: Int, _ flags: Int32) -> Int {
  #if canImport(Glibc)
    Glibc.send(fd, p, n, flags)
  #else
    Darwin.send(fd, p, n, flags)
  #endif
}

/// Keeps `fd` out of processes started later (git, ssh-keygen, GnuPG and its agent). On macOS a
/// child otherwise inherits every descriptor: one holding the socket keeps it answering after
/// Signet quits, and one holding a pipe's end keeps its reader from ever seeing the end.
func closeOnExec(_ fd: Int32) {
  _ = fcntl(fd, F_SETFD, fcntl(fd, F_GETFD) | FD_CLOEXEC)
}
