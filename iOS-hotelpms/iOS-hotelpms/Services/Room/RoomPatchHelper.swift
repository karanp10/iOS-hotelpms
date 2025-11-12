import Foundation

/// Generic helper for building room update patches with type safety and reduced boilerplate
struct RoomPatch: Codable {
    private var updates: [String: Any] = [:]
    
    enum CodingKeys: String, CodingKey {
        case occupancyStatus = "occupancy_status"
        case cleaningStatus = "cleaning_status"
        case flags
        case notes
        case updatedBy = "updated_by"
        case updatedAt = "updated_at"
    }
    
    init() {}
    
    /// Set occupancy status update
    mutating func setOccupancyStatus(_ status: OccupancyStatus) {
        updates[CodingKeys.occupancyStatus.rawValue] = status.rawValue
    }
    
    /// Set cleaning status update
    mutating func setCleaningStatus(_ status: CleaningStatus) {
        updates[CodingKeys.cleaningStatus.rawValue] = status.rawValue
    }
    
    /// Set room flags update
    mutating func setFlags(_ flags: [RoomFlag]) {
        updates[CodingKeys.flags.rawValue] = flags.map { $0.rawValue }
    }
    
    /// Set notes update
    mutating func setNotes(_ notes: String) {
        updates[CodingKeys.notes.rawValue] = notes
    }
    
    /// Set who updated the room
    mutating func setUpdatedBy(_ userId: UUID) {
        updates[CodingKeys.updatedBy.rawValue] = userId.uuidString
    }
    
    /// Set when the room was updated (defaults to now)
    mutating func setUpdatedAt(_ date: Date = Date()) {
        updates[CodingKeys.updatedAt.rawValue] = date.ISO8601Format()
    }
    
    /// Check if patch has any updates
    var isEmpty: Bool {
        return updates.isEmpty
    }
    
    /// Get the raw update dictionary for Supabase
    var updateData: [String: Any] {
        return updates
    }
    
    // MARK: - Codable Implementation
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        for (key, value) in updates {
            guard let codingKey = CodingKeys(rawValue: key) else { continue }
            
            switch value {
            case let stringValue as String:
                try container.encode(stringValue, forKey: codingKey)
            case let stringArrayValue as [String]:
                try container.encode(stringArrayValue, forKey: codingKey)
            default:
                // Handle any other types as needed
                break
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        updates = [:]
        
        // This is primarily for encoding, decoding not typically needed for patches
        if let occupancyStatus = try? container.decode(String.self, forKey: .occupancyStatus) {
            updates[CodingKeys.occupancyStatus.rawValue] = occupancyStatus
        }
        if let cleaningStatus = try? container.decode(String.self, forKey: .cleaningStatus) {
            updates[CodingKeys.cleaningStatus.rawValue] = cleaningStatus
        }
        if let flags = try? container.decode([String].self, forKey: .flags) {
            updates[CodingKeys.flags.rawValue] = flags
        }
        if let notes = try? container.decode(String.self, forKey: .notes) {
            updates[CodingKeys.notes.rawValue] = notes
        }
        if let updatedBy = try? container.decode(String.self, forKey: .updatedBy) {
            updates[CodingKeys.updatedBy.rawValue] = updatedBy
        }
        if let updatedAt = try? container.decode(String.self, forKey: .updatedAt) {
            updates[CodingKeys.updatedAt.rawValue] = updatedAt
        }
    }
}

/// Builder pattern for creating room patches
struct RoomPatchBuilder {
    private var patch = RoomPatch()
    
    init() {}
    
    func occupancy(_ status: OccupancyStatus) -> RoomPatchBuilder {
        var builder = self
        builder.patch.setOccupancyStatus(status)
        return builder
    }
    
    func cleaning(_ status: CleaningStatus) -> RoomPatchBuilder {
        var builder = self
        builder.patch.setCleaningStatus(status)
        return builder
    }
    
    func flags(_ flags: [RoomFlag]) -> RoomPatchBuilder {
        var builder = self
        builder.patch.setFlags(flags)
        return builder
    }
    
    func notes(_ notes: String) -> RoomPatchBuilder {
        var builder = self
        builder.patch.setNotes(notes)
        return builder
    }
    
    func updatedBy(_ userId: UUID) -> RoomPatchBuilder {
        var builder = self
        builder.patch.setUpdatedBy(userId)
        return builder
    }
    
    func updatedAt(_ date: Date = Date()) -> RoomPatchBuilder {
        var builder = self
        builder.patch.setUpdatedAt(date)
        return builder
    }
    
    func build() -> RoomPatch {
        return patch
    }
}

/// Convenience extension for creating room patches
extension RoomPatch {
    static func builder() -> RoomPatchBuilder {
        return RoomPatchBuilder()
    }
    
    /// Create a simple occupancy status patch
    static func occupancyUpdate(_ status: OccupancyStatus, updatedBy userId: UUID) -> RoomPatch {
        return builder()
            .occupancy(status)
            .updatedBy(userId)
            .updatedAt()
            .build()
    }
    
    /// Create a simple cleaning status patch
    static func cleaningUpdate(_ status: CleaningStatus, updatedBy userId: UUID) -> RoomPatch {
        return builder()
            .cleaning(status)
            .updatedBy(userId)
            .updatedAt()
            .build()
    }
    
    /// Create a simple flags patch
    static func flagsUpdate(_ flags: [RoomFlag], updatedBy userId: UUID) -> RoomPatch {
        return builder()
            .flags(flags)
            .updatedBy(userId)
            .updatedAt()
            .build()
    }
}