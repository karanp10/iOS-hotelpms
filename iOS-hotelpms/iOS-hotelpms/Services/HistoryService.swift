import Foundation
import Supabase

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

class HistoryService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    enum HistoryError: LocalizedError {
        case networkError(String)
        case userNotAuthenticated
        
        var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return "Network error: \(message)"
            case .userNotAuthenticated:
                return "User must be authenticated"
            }
        }
    }
    
    /// Fetch recent room history entries (simplified version)
    func getRecentHistory(for hotelId: UUID, limit: Int = 50) async throws -> [RoomHistoryEntry] {
        do {
            let response: [RoomHistoryEntry] = try await supabase
                .from("room_history")
                .select()
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw HistoryError.networkError(error.localizedDescription)
        }
    }
    
    /// Fetch history for a specific room
    func getHistoryForRoom(_ roomId: UUID, limit: Int = 20) async throws -> [RoomHistoryEntry] {
        do {
            let response: [RoomHistoryEntry] = try await supabase
                .from("room_history")
                .select()
                .eq("room_id", value: roomId.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw HistoryError.networkError(error.localizedDescription)
        }
    }
    
    /// Filter history by change type
    func getHistoryByType(for hotelId: UUID, changeType: String, limit: Int = 30) async throws -> [RoomHistoryEntry] {
        do {
            let response: [RoomHistoryEntry] = try await supabase
                .from("room_history")
                .select()
                .eq("change_type", value: changeType)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw HistoryError.networkError(error.localizedDescription)
        }
    }
}