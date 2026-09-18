import Foundation

struct QDataStreamReader {
    var data: Data
    var offset: Int = 0
    
    init(data: Data) {
        self.data = data
    }
    
    mutating func readUInt32() -> UInt32? {
        guard offset + 4 <= data.count else { return nil }
        var val: UInt32 = 0
        _ = withUnsafeMutableBytes(of: &val) { ptr in
            data.copyBytes(to: ptr, from: offset..<offset+4)
        }
        offset += 4
        return UInt32(bigEndian: val)
    }
    
    mutating func readInt32() -> Int32? {
        guard offset + 4 <= data.count else { return nil }
        var val: Int32 = 0
        _ = withUnsafeMutableBytes(of: &val) { ptr in
            data.copyBytes(to: ptr, from: offset..<offset+4)
        }
        offset += 4
        return Int32(bigEndian: val)
    }
    
    mutating func readUInt64() -> UInt64? {
        guard offset + 8 <= data.count else { return nil }
        var val: UInt64 = 0
        _ = withUnsafeMutableBytes(of: &val) { ptr in
            data.copyBytes(to: ptr, from: offset..<offset+8)
        }
        offset += 8
        return UInt64(bigEndian: val)
    }
    
    mutating func readUInt8() -> UInt8? {
        guard offset + 1 <= data.count else { return nil }
        let val = data[offset]
        offset += 1
        return val
    }
    
    mutating func readBool() -> Bool? {
        guard let val = readUInt8() else { return nil }
        return val != 0
    }
    
    mutating func readDouble() -> Double? {
        guard offset + 8 <= data.count else { return nil }
        var val: UInt64 = 0
        _ = withUnsafeMutableBytes(of: &val) { ptr in
            data.copyBytes(to: ptr, from: offset..<offset+8)
        }
        offset += 8
        return Double(bitPattern: UInt64(bigEndian: val))
    }
    
    mutating func readFloat() -> Float? {
        guard offset + 4 <= data.count else { return nil }
        var val: UInt32 = 0
        _ = withUnsafeMutableBytes(of: &val) { ptr in
            data.copyBytes(to: ptr, from: offset..<offset+4)
        }
        offset += 4
        return Float(bitPattern: UInt32(bigEndian: val))
    }
    
    mutating func readString() -> String? {
        guard let length = readUInt32() else { return nil }
        if length == 0xFFFFFFFF || length == 0 { return "" } // Null string in QDataStream
        guard offset + Int(length) <= data.count else { return nil }
        let strData = data[offset..<offset+Int(length)]
        offset += Int(length)
        return String(data: strData, encoding: .utf8) ?? ""
    }
    
    mutating func readTime() -> UInt32? {
        // QTime is sent as milliseconds since midnight
        return readUInt32()
    }
}

struct QDataStreamWriter {
    var data = Data()
    
    mutating func writeUInt32(_ val: UInt32) {
        var big = val.bigEndian
        data.append(Data(bytes: &big, count: 4))
    }
    
    mutating func writeInt32(_ val: Int32) {
        var big = val.bigEndian
        data.append(Data(bytes: &big, count: 4))
    }
    
    mutating func writeUInt8(_ val: UInt8) {
        data.append(val)
    }
    
    mutating func writeBool(_ val: Bool) {
        writeUInt8(val ? 1 : 0)
    }
    
    mutating func writeDouble(_ val: Double) {
        var big = val.bitPattern.bigEndian
        data.append(Data(bytes: &big, count: 8))
    }
    
    mutating func writeFloat(_ val: Float) {
        var big = val.bitPattern.bigEndian
        data.append(Data(bytes: &big, count: 4))
    }
    
    mutating func writeString(_ str: String?) {
        guard let str = str, let strData = str.data(using: .utf8) else {
            writeUInt32(0xFFFFFFFF)
            return
        }
        writeUInt32(UInt32(strData.count))
        data.append(strData)
    }
    
    mutating func writeTime(_ msSinceMidnight: UInt32) {
        writeUInt32(msSinceMidnight)
    }
}
