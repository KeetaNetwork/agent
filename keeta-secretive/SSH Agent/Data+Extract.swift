import Foundation

extension Data {
    mutating func extractFirst() -> UInt8 {
        let result = self[0]
        self = dropFirst()
        return result
    }
    
    mutating func extractFirst(_ k: Int) -> Data {
        let range = 0..<k
        let subData = subdata(in: range)
        removeSubrange(range)
        return subData
    }
    
    var length: Int {
        let littleEndianLength = withUnsafeBytes { $0.load(as: UInt32.self) }
        return Int(littleEndianLength.bigEndian)
    }
}
