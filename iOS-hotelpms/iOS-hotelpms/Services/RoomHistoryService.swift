import Foundation
import Supabase

/// Service responsible for both logging room history (audit trail) and querying historical data.
/// Combines functionality from previous AuditService and HistoryService.
class RoomHistoryService {
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }
    
    // MARK: - Audit Record Creation (Write Operations)
    
    func createAuditRecord(
        roomId: UUID,
        actorId: UUID,
        eventType: String,
        prevValue: String?,
        newValue: String?,
        reason: String?
    ) async throws {
        // Validate event type
        guard AuditEventType.allCases.map({ $0.rawValue }).contains(eventType) else {
            throw RoomHistoryServiceError.invalidEventType(eventType)
        }
        
        let auditRequest = CreateAuditRequest(
            roomId: roomId,
            actorId: actorId,
            eventType: eventType,
            prevValue: prevValue,
            newValue: newValue,
            reason: reason
        )
        
        do {
            let _ = try await supabaseClient
                .from("room_history")
                .insert(auditRequest)
                .execute()
        } catch {
            throw RoomHistoryServiceError.networkError("Failed to create audit record: \(error.localizedDescription)")
        }
    }
    
    func createBulkAuditRecords(_ records: [CreateAuditRequest]) async throws {
        guard !records.isEmpty else { return }
        
        // Validate all event types
        for record in records {
            guard AuditEventType.allCases.map({ $0.rawValue }).contains(record.changeType) else {
                throw RoomHistoryServiceError.invalidEventType(record.changeType)
            }
        }
        
        do {
            let _ = try await supabaseClient
                .from("room_history")
                .insert(records)
                .execute()
        } catch {
            throw RoomHistoryServiceError.networkError("Failed to create bulk audit records: \(error.localizedDescription)")
        }
    }
    
    // MARK: - History Retrieval (Read Operations)
    
    func getRoomHistory(roomId: UUID, limit: Int = 50) async throws -> [RoomHistoryEntry] {
        do {
            let response: [RoomHistoryEntry] = try await supabaseClient
                .from("room_history")
                .select()
                .eq("room_id", value: roomId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomHistoryServiceError.networkError("Failed to get room history: \(error.localizedDescription)")
        }
    }
    
    func getRecentActivity(limit: Int = 100) async throws -> [RoomHistoryEntry] {
        do {
            let response: [RoomHistoryEntry] = try await supabaseClient
                .from("room_history")
                .select()
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomHistoryServiceError.networkError("Failed to get recent activity: \(error.localizedDescription)")
        }
    }
    
    func getRecentHistoryForHotel(hotelId: UUID, limit: Int = 50) async throws -> [RoomHistoryEntry] {
        do {
            let response: [RoomHistoryEntry] = try await supabaseClient
                .from("room_history")
                .select()
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomHistoryServiceError.networkError("Failed to get recent hotel history: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Activity Filtering
    
    func getActivityByType(eventType: AuditEventType, limit: Int = 50) async throws -> [RoomHistoryEntry] {
        do {
            let response: [RoomHistoryEntry] = try await supabaseClient
                .from("room_history")
                .select()
                .eq("change_type", value: eventType.rawValue)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomHistoryServiceError.networkError("Failed to get activity by type: \(error.localizedDescription)")
        }
    }
    
    func getActivityByChangeType(changeType: String, limit: Int = 30) async throws -> [RoomHistoryEntry] {
        do {
            let response: [RoomHistoryEntry] = try await supabaseClient
                .from("room_history")
                .select()
                .eq("change_type", value: changeType)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomHistoryServiceError.networkError("Failed to get activity by change type: \(error.localizedDescription)")
        }
    }
    
    func getActivityByActor(actorId: UUID, limit: Int = 50) async throws -> [RoomHistoryEntry] {
        do {
            let response: [RoomHistoryEntry] = try await supabaseClient
                .from("room_history")
                .select()
                .eq("changed_by", value: actorId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomHistoryServiceError.networkError("Failed to get activity by actor: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Convenience Methods for Common Audit Operations
    
    func logOccupancyChange(roomId: UUID, actorId: UUID, from: OccupancyStatus, to: OccupancyStatus, reason: String? = nil) async throws {
        try await createAuditRecord(
            roomId: roomId,
            actorId: actorId,
            eventType: AuditEventType.occupancyStatus.rawValue,
            prevValue: from.rawValue,
            newValue: to.rawValue,
            reason: reason
        )
    }
    
    func logCleaningChange(roomId: UUID, actorId: UUID, from: CleaningStatus, to: CleaningStatus, reason: String? = nil) async throws {
        try await createAuditRecord(
            roomId: roomId,
            actorId: actorId,
            eventType: AuditEventType.cleaningStatus.rawValue,
            prevValue: from.rawValue,
            newValue: to.rawValue,
            reason: reason
        )
    }
    
    func logFlagAdded(roomId: UUID, actorId: UUID, flag: RoomFlag, reason: String? = nil) async throws {
        try await createAuditRecord(
            roomId: roomId,
            actorId: actorId,
            eventType: AuditEventType.flags.rawValue,
            prevValue: nil,
            newValue: "added: \(flag.rawValue)",
            reason: reason
        )
    }
    
    func logFlagRemoved(roomId: UUID, actorId: UUID, flag: RoomFlag, reason: String? = nil) async throws {
        try await createAuditRecord(
            roomId: roomId,
            actorId: actorId,
            eventType: AuditEventType.flags.rawValue,
            prevValue: "removed: \(flag.rawValue)",
            newValue: nil,
            reason: reason
        )
    }
    
    func logNoteAdded(roomId: UUID, actorId: UUID, noteText: String, reason: String? = nil) async throws {
        try await createAuditRecord(
            roomId: roomId,
            actorId: actorId,
            eventType: AuditEventType.notes.rawValue,
            prevValue: nil,
            newValue: noteText,
            reason: reason ?? "Note added"
        )
    }
    
    func logNoteUpdated(roomId: UUID, actorId: UUID, oldText: String, newText: String, reason: String? = nil) async throws {
        try await createAuditRecord(
            roomId: roomId,
            actorId: actorId,
            eventType: AuditEventType.notes.rawValue,
            prevValue: oldText,
            newValue: newText,
            reason: reason ?? "Note updated"
        )
    }
    
    func logNoteDeleted(roomId: UUID, actorId: UUID, deletedText: String, reason: String? = nil) async throws {
        try await createAuditRecord(
            roomId: roomId,
            actorId: actorId,
            eventType: AuditEventType.notes.rawValue,
            prevValue: deletedText,
            newValue: nil,
            reason: reason ?? "Note deleted"
        )
    }
}

// MARK: - Supporting Types

struct CreateAuditRequest: Codable {
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
    
    init(roomId: UUID, actorId: UUID, eventType: String, prevValue: String?, newValue: String?, reason: String?) {
        self.roomId = roomId
        self.changedBy = actorId
        self.changeType = eventType
        self.oldValue = prevValue
        self.newValue = newValue
        self.note = reason
        self.createdAt = Date()
    }
}

enum AuditEventType: String, CaseIterable {
    case occupancyStatus = "occupancy_status"
    case cleaningStatus = "cleaning_status"
    case flags = "flags"
    case notes = "notes"
    case created = "created"
    
    var displayName: String {
        switch self {
        case .occupancyStatus:
            return "Occupancy Changed"
        case .cleaningStatus:
            return "Cleaning Status Changed"
        case .flags:
            return "Flags Changed"
        case .notes:
            return "Notes Changed"
        case .created:
            return "Room Created"
        }
    }
}

// MARK: - Room History Service Errors

enum RoomHistoryServiceError: LocalizedError {
    case invalidEventType(String)
    case networkError(String)
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidEventType(let eventType):
            return "Invalid event type: \(eventType)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        }
    }
}