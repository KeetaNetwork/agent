import Foundation

/// Protocol abstraction of the reading aspects of FileHandle.
protocol FileHandleReader {
    /// Gets data that is available for reading.
    var availableData: Data { get }
    /// The  process ID of the process coonnected to the other end of the FileHandle.
    var pidOfConnectedProcess: Int32 { get }
}

/// Protocol abstraction of the writing aspects of FileHandle.
protocol FileHandleWriter {
    /// Writes data to the handle.
    func write(_ data: Data)
}

extension FileHandle: FileHandleReader, FileHandleWriter {
    var pidOfConnectedProcess: Int32 {
        let pidPointer = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: 1)
        var len = socklen_t(MemoryLayout<Int32>.size)
        getsockopt(fileDescriptor, SOCK_STREAM, LOCAL_PEERPID, pidPointer, &len)
        return pidPointer.load(as: Int32.self)
    }
}
