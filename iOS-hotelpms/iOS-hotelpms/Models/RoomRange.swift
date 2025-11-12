import Foundation

struct RoomRange {
    var id = UUID()
    var startRoom: String = ""
    var endRoom: String = ""
    
    var isValid: Bool {
        guard let start = Int(startRoom), let end = Int(endRoom) else { return false }
        return start > 0 && end > 0 && start <= end
    }
    
    var roomCount: Int {
        guard let start = Int(startRoom), let end = Int(endRoom), isValid else { return 0 }
        return end - start + 1
    }
    
    var displayText: String {
        if isValid {
            return "\(startRoom)-\(endRoom) (\(roomCount) rooms)"
        } else {
            return "Invalid range"
        }
    }
    
    var intRange: ClosedRange<Int>? {
        guard let start = Int(startRoom), let end = Int(endRoom), isValid else { return nil }
        return start...end
    }
}

// MARK: - RoomRange Validation Helpers
extension Array where Element == RoomRange {
    
    var totalRoomCount: Int {
        self.filter { $0.isValid }.reduce(0) { $0 + $1.roomCount }
    }
    
    var hasOverlappingRanges: Bool {
        let validRanges = self.compactMap { $0.intRange }
        
        for i in 0..<validRanges.count {
            for j in (i+1)..<validRanges.count {
                if validRanges[i].overlaps(validRanges[j]) {
                    return true
                }
            }
        }
        return false
    }
    
    var isValidConfiguration: Bool {
        return !self.isEmpty &&
               self.allSatisfy { $0.isValid } &&
               !hasOverlappingRanges &&
               totalRoomCount > 0
    }
    
    var validRanges: [RoomRange] {
        return self.filter { $0.isValid }
    }
    
    var validRangesDisplayText: String {
        return validRanges.map { $0.displayText }.joined(separator: ", ")
    }
}