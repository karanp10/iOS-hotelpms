import Foundation

// MARK: - Room History Models

struct RoomHistoryEntry: Codable, Identifiable {
    let id: UUID
    let roomId: UUID
    let changedBy: UUID?
    let changeType: String
    let oldValue: String?
    let newValue: String?
    let note: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomId = "room_id"
        case changedBy = "changed_by"
        case changeType = "change_type"
        case oldValue = "old_value"
        case newValue = "new_value"
        case note
        case createdAt = "created_at"
    }
    
    // Computed properties for display
    var displayUserName: String {
        return "User" // Simplified for now
    }
    
    var displayChangeDescription: String {
        let roomDisplay = "Room"
        
        switch changeType {
        case "occupancy_status":
            if let oldValue = oldValue, let newValue = newValue {
                return "Set \(roomDisplay) from \(oldValue.capitalized) → \(newValue.capitalized)"
            }
            return "Updated occupancy for \(roomDisplay)"
            
        case "cleaning_status":
            if let oldValue = oldValue, let newValue = newValue {
                return "Set \(roomDisplay) from \(formatCleaningStatus(oldValue)) → \(formatCleaningStatus(newValue))"
            }
            return "Updated cleaning status for \(roomDisplay)"
            
        case "flags":
            if let newValue = newValue, !newValue.isEmpty {
                return "Added flag to \(roomDisplay): \(newValue)"
            }
            return "Updated flags for \(roomDisplay)"
            
        case "notes":
            return "Added note to \(roomDisplay)"
            
        case "created":
            return "Created \(roomDisplay)"
            
        default:
            return "Updated \(roomDisplay)"
        }
    }
    
    private func formatCleaningStatus(_ status: String) -> String {
        switch status {
        case "dirty": return "Dirty"
        case "cleaning_in_progress": return "Cleaning In Progress"
        case "ready": return "Ready"
        default: return status.capitalized
        }
    }
    
    var changeTypeIcon: String {
        switch changeType {
        case "occupancy_status": return "bed.double.fill"
        case "cleaning_status": return "broom.fill"
        case "flags": return "wrench.fill"
        case "notes": return "note.text"
        case "created": return "plus.circle.fill"
        default: return "circle.fill"
        }
    }
}

struct RoomHistoryRequest: Codable {
    let roomId: UUID
    let changedBy: UUID
    let changeType: String
    let oldValue: String?
    let newValue: String?
    let note: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case changedBy = "changed_by"
        case changeType = "change_type"
        case oldValue = "old_value"
        case newValue = "new_value"
        case note
        case createdAt = "created_at"
    }
    
    init(roomId: UUID, changedBy: UUID, changeType: String, oldValue: String?, newValue: String?, note: String?) {
        self.roomId = roomId
        self.changedBy = changedBy
        self.changeType = changeType
        self.oldValue = oldValue
        self.newValue = newValue
        self.note = note
        self.createdAt = Date()
    }
}

struct RoomNote: Codable, Identifiable {
    let id: UUID
    let roomId: UUID
    let authorId: UUID?
    let note: String
    let createdAt: Date?
    let deletedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomId = "room_id"
        case authorId = "author_id" 
        case note
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
    
    var isRecent: Bool {
        guard let createdAt = createdAt else { return false }
        let twoDaysAgo = Calendar.current.date(byAdding: .hour, value: -48, to: Date()) ?? Date()
        return createdAt > twoDaysAgo
    }
    
    var preview: String {
        note.count > 50 ? String(note.prefix(47)) + "..." : note
    }
    
    var body: String {
        return note // For backward compatibility with UI code
    }
}