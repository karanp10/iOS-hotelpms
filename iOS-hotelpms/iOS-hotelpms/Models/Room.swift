import Foundation

enum OccupancyStatus: String, CaseIterable, Codable {
    case vacant = "vacant"
    case assigned = "assigned"
    case occupied = "occupied"
    case stayover = "stayover"
    case checkedOut = "checked_out"
    
    var displayName: String {
        switch self {
        case .vacant: return "Vacant"
        case .assigned: return "Assigned"
        case .occupied: return "Occupied"
        case .stayover: return "Stayover"
        case .checkedOut: return "Checked Out"
        }
    }
    
    var color: String {
        switch self {
        case .vacant: return "gray"
        case .assigned: return "blue"
        case .occupied: return "green"
        case .stayover: return "orange"
        case .checkedOut: return "red"
        }
    }
}

enum CleaningStatus: String, CaseIterable, Codable {
    case dirty = "dirty"
    case cleaningInProgress = "cleaning_in_progress"
    case ready = "ready"
    
    var displayName: String {
        switch self {
        case .dirty: return "Dirty"
        case .cleaningInProgress: return "Cleaning"
        case .ready: return "Ready"
        }
    }
    
    var color: String {
        switch self {
        case .dirty: return "red"
        case .cleaningInProgress: return "yellow"
        case .ready: return "green"
        }
    }
    
    var systemImage: String {
        switch self {
        case .dirty: return "exclamationmark.triangle.fill"
        case .cleaningInProgress: return "clock.fill"
        case .ready: return "checkmark.circle.fill"
        }
    }
}

enum RoomFlag: String, CaseIterable, Codable {
    case maintenanceRequired = "maintenance_required"
    case outOfOrder = "out_of_order"
    case outOfService = "out_of_service"
    case dnd = "dnd"
    
    var displayName: String {
        switch self {
        case .maintenanceRequired: return "Maintenance"
        case .outOfOrder: return "OOO"
        case .outOfService: return "OOS"
        case .dnd: return "DND"
        }
    }
    
    var color: String {
        switch self {
        case .maintenanceRequired: return "orange"
        case .outOfOrder: return "red"
        case .outOfService: return "red"
        case .dnd: return "purple"
        }
    }
    
    var systemImage: String {
        switch self {
        case .maintenanceRequired: return "wrench.fill"
        case .outOfOrder: return "xmark.circle.fill"
        case .outOfService: return "minus.circle.fill"
        case .dnd: return "moon.fill"
        }
    }
}

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
}

// Request model for creating rooms
struct CreateRoomRequest: Codable {
    let hotelId: UUID
    let roomNumber: Int
    let floorNumber: Int
    let occupancyStatus: String
    let cleaningStatus: String
    let flags: [String]
    
    enum CodingKeys: String, CodingKey {
        case hotelId = "hotel_id"
        case roomNumber = "room_number"
        case floorNumber = "floor_number"
        case occupancyStatus = "occupancy_status"
        case cleaningStatus = "cleaning_status"
        case flags
    }
    
    init(room: Room) {
        self.hotelId = room.hotelId
        self.roomNumber = room.roomNumber
        self.floorNumber = room.floorNumber
        self.occupancyStatus = room.occupancyStatus.rawValue
        self.cleaningStatus = room.cleaningStatus.rawValue
        self.flags = room.flags.map { $0.rawValue }
    }
}