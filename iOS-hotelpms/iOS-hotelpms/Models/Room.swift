import Foundation

// MARK: - Room Entity Model

struct Room: Codable, Identifiable, Hashable {
    let id: UUID
    let hotelId: UUID
    let roomNumber: Int
    let floorNumber: Int
    let occupancyStatus: OccupancyStatus
    let cleaningStatus: CleaningStatus
    let flags: [RoomFlag]
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case hotelId = "hotel_id"
        case roomNumber = "room_number"
        case floorNumber = "floor_number"
        case occupancyStatus = "occupancy_status"
        case cleaningStatus = "cleaning_status"
        case flags
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoding to handle flag arrays from database
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        hotelId = try container.decode(UUID.self, forKey: .hotelId)
        roomNumber = try container.decode(Int.self, forKey: .roomNumber)
        floorNumber = try container.decode(Int.self, forKey: .floorNumber)
        
        // Decode enum strings to enum cases
        let occupancyRawValue = try container.decode(String.self, forKey: .occupancyStatus)
        occupancyStatus = OccupancyStatus(rawValue: occupancyRawValue) ?? .vacant
        
        let cleaningRawValue = try container.decode(String.self, forKey: .cleaningStatus)
        cleaningStatus = CleaningStatus(rawValue: cleaningRawValue) ?? .dirty
        
        // Handle flags array - database stores as text array
        let flagStrings = try container.decode([String].self, forKey: .flags)
        flags = flagStrings.compactMap { RoomFlag(rawValue: $0) }
        
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    // Custom encoding to handle flag arrays to database
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(hotelId, forKey: .hotelId)
        try container.encode(roomNumber, forKey: .roomNumber)
        try container.encode(floorNumber, forKey: .floorNumber)
        try container.encode(occupancyStatus.rawValue, forKey: .occupancyStatus)
        try container.encode(cleaningStatus.rawValue, forKey: .cleaningStatus)
        
        // Convert flags to string array for database
        let flagStrings = flags.map { $0.rawValue }
        try container.encode(flagStrings, forKey: .flags)
        
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    // Initializer for creating new rooms
    init(
        id: UUID = UUID(),
        hotelId: UUID,
        roomNumber: Int,
        floorNumber: Int,
        occupancyStatus: OccupancyStatus = .vacant,
        cleaningStatus: CleaningStatus = .dirty,
        flags: [RoomFlag] = [],
        notes: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.hotelId = hotelId
        self.roomNumber = roomNumber
        self.floorNumber = floorNumber
        self.occupancyStatus = occupancyStatus
        self.cleaningStatus = cleaningStatus
        self.flags = flags
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var displayNumber: String {
        return String(roomNumber)
    }
    
    var hasFlags: Bool {
        return !flags.isEmpty
    }
    
    var needsAttention: Bool {
        return flags.contains(.maintenanceRequired) || 
               flags.contains(.outOfOrder) || 
               flags.contains(.outOfService) ||
               cleaningStatus == .dirty
    }
    
    var hasNotes: Bool {
        return notes != nil && !notes!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var notesPreview: String? {
        guard hasNotes, let notes = notes else { return nil }
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 15 ? String(trimmed.prefix(12)) + "..." : trimmed
    }
    
    // Helper to calculate floor from room number
    static func calculateFloor(from roomNumber: Int) -> Int {
        // Standard hotel convention: room 205 is on floor 2
        return roomNumber / 100
    }

    // MARK: - Housekeeping Helpers

    /// Computed property for cleaning priority
    var cleaningPriority: CleaningPriority {
        return CleaningPriority.priority(for: self)
    }

    /// Check if room can start cleaning (dirty or checked out)
    func canStartCleaning() -> Bool {
        return cleaningStatus == .dirty || occupancyStatus == .checkedOut
    }

    /// Check if room can be marked as ready (currently in progress)
    func canMarkReady() -> Bool {
        return cleaningStatus == .cleaningInProgress
    }

    /// Check if room is in the cleaning workflow (not ready)
    var needsCleaning: Bool {
        return cleaningStatus != .ready
    }

    // MARK: - Maintenance Helpers

    /// Check if room has maintenance-related flags
    var hasMaintenanceFlag: Bool {
        return flags.contains(.maintenanceRequired) ||
               flags.contains(.outOfOrder) ||
               flags.contains(.outOfService)
    }

    /// Check if room is out of service
    var isOutOfService: Bool {
        return flags.contains(.outOfService)
    }

    /// Get only maintenance-related flags
    func maintenanceFlags() -> [RoomFlag] {
        return flags.filter {
            $0 == .maintenanceRequired || $0 == .outOfOrder || $0 == .outOfService
        }
    }

    // MARK: - Front Desk Helpers

    /// Check if room is available for assignment (vacant and ready)
    var isAvailable: Bool {
        return occupancyStatus == .vacant && cleaningStatus == .ready
    }

    /// Check if guest can check in
    func canCheckIn() -> Bool {
        return (occupancyStatus == .vacant || occupancyStatus == .assigned) &&
               cleaningStatus == .ready
    }

    /// Check if guest can check out
    func canCheckOut() -> Bool {
        return occupancyStatus == .occupied || occupancyStatus == .stayover
    }
}

