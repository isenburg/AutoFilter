import Foundation

struct QSOEntry: Identifiable, Codable {
    var id = UUID()
    var callsign: String
    var band: String
    var mode: String
    var qsoDate: String
    var timeOn: String
    var dxcc: String
    
    var formattedDate: String {
        let clean = qsoDate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count == 8 else { return clean }
        
        let year = String(clean.prefix(4))
        let month = String(clean.dropFirst(4).prefix(2))
        let day = String(clean.suffix(2))
        
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)
        components.day = Int(day)
        
        if let date = Calendar.current.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = Locale.current
            return formatter.string(from: date)
        }
        return clean
    }
    
    var formattedTime: String {
        let clean = timeOn.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 4 else { return clean }
        
        let hour = String(clean.prefix(2))
        let minute = String(clean.dropFirst(2).prefix(2))
        let second = clean.count >= 6 ? String(clean.dropFirst(4).prefix(2)) : "00"
        
        var components = DateComponents()
        components.hour = Int(hour)
        components.minute = Int(minute)
        components.second = Int(second)
        
        if let date = Calendar.current.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            formatter.locale = Locale.current
            return formatter.string(from: date)
        }
        return clean
    }
    
    var uniqueKey: String {
        let cleanTime = timeOn.trimmingCharacters(in: .whitespacesAndNewlines)
        let time4 = cleanTime.count >= 4 ? String(cleanTime.prefix(4)) : cleanTime
        return "\(callsign.uppercased())_\(band.uppercased())_\(mode.uppercased())_\(qsoDate)_\(time4)"
    }
}

struct ADIFParser {
    static func parseQSOs(from adifString: String) -> [QSOEntry] {
        var entries = [QSOEntry]()
        
        // Strip header before <EOH> (case-insensitive)
        var content = adifString
        if let eohRange = content.range(of: "<EOH>", options: .caseInsensitive) {
            content = String(content[eohRange.upperBound...])
        }
        
        // Split records case-insensitively using regex
        let regex = try! NSRegularExpression(pattern: "(?i)<eor>")
        let records = content.components(separatedBy: regex)
        
        for record in records {
            let upperRecord = record.uppercased()
            guard let call = extractTagValue("CALL", from: upperRecord),
                  let band = extractTagValue("BAND", from: upperRecord) else { continue }
            
            var mode = extractTagValue("MODE", from: upperRecord) ?? ""
            if let submode = extractTagValue("SUBMODE", from: upperRecord), !submode.isEmpty {
                mode = submode
            }
            
            let qsoDate = extractTagValue("QSO_DATE", from: upperRecord) ?? ""
            let timeOn = extractTagValue("TIME_ON", from: upperRecord) ?? ""
            let dxcc = extractTagValue("DXCC", from: upperRecord) ?? ""
            
            let entry = QSOEntry(callsign: call, band: band, mode: mode, qsoDate: qsoDate, timeOn: timeOn, dxcc: dxcc)
            entries.append(entry)
        }
        return entries
    }
    
    private static func extractTagValue(_ tag: String, from record: String) -> String? {
        let tagPrefix = "<\(tag):"
        guard let startRange = record.range(of: tagPrefix) else { return nil }
        let tail = record[startRange.upperBound...]
        guard let colonOrGreater = tail.firstIndex(where: { $0 == ">" || $0 == ":" }) else { return nil }
        
        let lengthString = tail[..<colonOrGreater]
        guard let length = Int(lengthString) else { return nil }
        
        guard let endOfTag = tail.firstIndex(of: ">") else { return nil }
        let valueStart = tail.index(after: endOfTag)
        
        guard let valueEnd = tail.index(valueStart, offsetBy: length, limitedBy: tail.endIndex) else { return nil }
        return String(tail[valueStart..<valueEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension String {
    func components(separatedBy regex: NSRegularExpression) -> [String] {
        let nsString = self as NSString
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length))
        var result = [String]()
        var lastIndex = 0
        for match in matches {
            let range = NSRange(location: lastIndex, length: match.range.location - lastIndex)
            result.append(nsString.substring(with: range))
            lastIndex = match.range.location + match.range.length
        }
        if lastIndex < nsString.length {
            let range = NSRange(location: lastIndex, length: nsString.length - lastIndex)
            result.append(nsString.substring(with: range))
        }
        return result
    }
}
