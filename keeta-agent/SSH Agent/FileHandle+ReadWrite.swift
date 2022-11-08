import Foundation

/// Protocol abstraction of the reading aspects of FileHandle.
protocol FileHandleReader {
    /// Gets data that is available for reading.
    var availableData: Data { get }
}

/// Protocol abstraction of the writing aspects of FileHandle.
protocol FileHandleWriter {
    /// Writes data to the handle.
    func write(_ data: Data)
}

extension FileHandle: FileHandleReader, FileHandleWriter {}
