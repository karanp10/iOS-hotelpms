import Foundation
import Supabase

class RoomService {
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }
    
    // MARK: - Room Retrieval
    
    func getRooms(hotelId: UUID) async throws -> [Room] {
        do {
            let response: [Room] = try await supabaseClient
                .from("rooms")
                .select()
                .eq("hotel_id", value: hotelId)
                .order("room_number", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw DatabaseError.networkError("Failed to get rooms: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Room Status Updates
    
    func updateOccupancyStatus(roomId: UUID, newStatus: OccupancyStatus, updatedBy: UUID?) async throws {
        do {
            let updateRequest = RoomOccupancyUpdate(
                occupancyStatus: newStatus.rawValue,
                updatedBy: updatedBy,
                updatedAt: Date().ISO8601Format()
            )
            
            let _ = try await supabaseClient
                .from("rooms")
                .update(updateRequest)
                .eq("id", value: roomId)
                .execute()
            
        } catch {
            throw DatabaseError.networkError("Failed to update occupancy status: \(error.localizedDescription)")
        }
    }
    
    func updateCleaningStatus(roomId: UUID, newStatus: CleaningStatus, updatedBy: UUID?) async throws {
        do {
            let updateRequest = RoomCleaningUpdate(
                cleaningStatus: newStatus.rawValue,
                updatedBy: updatedBy,
                updatedAt: Date().ISO8601Format()
            )
            
            let _ = try await supabaseClient
                .from("rooms")
                .update(updateRequest)
                .eq("id", value: roomId)
                .execute()
            
        } catch {
            throw DatabaseError.networkError("Failed to update cleaning status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Flag Management
    
    func toggleFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID?) async throws {
        do {
            // First get current room to check existing flags
            let currentRooms: [Room] = try await supabaseClient
                .from("rooms")
                .select()
                .eq("id", value: roomId)
                .execute()
                .value
            
            guard let currentRoom = currentRooms.first else {
                throw DatabaseError.networkError("Room not found")
            }
            
            // Toggle flag in array
            var newFlags = currentRoom.flags
            if newFlags.contains(flag) {
                newFlags.removeAll { $0 == flag }
            } else {
                newFlags.append(flag)
            }
            
            // Update room with new flags
            let updateRequest = RoomFlagsUpdate(
                flags: newFlags.map { $0.rawValue },
                updatedBy: updatedBy,
                updatedAt: Date().ISO8601Format()
            )
            
            let _ = try await supabaseClient
                .from("rooms")
                .update(updateRequest)
                .eq("id", value: roomId)
                .execute()
            
        } catch {
            throw DatabaseError.networkError("Failed to toggle flag: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Room Creation
    
    func createRoom(_ request: CreateRoomRequest) async throws {
        do {
            let _ = try await supabaseClient
                .from("rooms")
                .insert(request)
                .execute()
            
        } catch {
            throw DatabaseError.networkError("Failed to create room: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Room Updates (Batch)
    
    func updateRoom(roomId: UUID, updates: RoomUpdateRequest, updatedBy: UUID?) async throws {
        do {
            let updateRequest = RoomBatchUpdate(
                occupancyStatus: updates.occupancyStatus?.rawValue,
                cleaningStatus: updates.cleaningStatus?.rawValue,
                flags: updates.flags?.map { $0.rawValue },
                notes: updates.notes,
                updatedBy: updatedBy,
                updatedAt: Date().ISO8601Format()
            )
            
            let _ = try await supabaseClient
                .from("rooms")
                .update(updateRequest)
                .eq("id", value: roomId)
                .execute()
            
        } catch {
            throw DatabaseError.networkError("Failed to update room: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

struct RoomUpdateRequest {
    let occupancyStatus: OccupancyStatus?
    let cleaningStatus: CleaningStatus?
    let flags: [RoomFlag]?
    let notes: String?
    
    init(
        occupancyStatus: OccupancyStatus? = nil,
        cleaningStatus: CleaningStatus? = nil,
        flags: [RoomFlag]? = nil,
        notes: String? = nil
    ) {
        self.occupancyStatus = occupancyStatus
        self.cleaningStatus = cleaningStatus
        self.flags = flags
        self.notes = notes
    }
}

// MARK: - Codable Update Structs

struct RoomOccupancyUpdate: Codable {
    let occupancyStatus: String
    let updatedBy: UUID?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case occupancyStatus = "occupancy_status"
        case updatedBy = "updated_by"
        case updatedAt = "updated_at"
    }
}

struct RoomCleaningUpdate: Codable {
    let cleaningStatus: String
    let updatedBy: UUID?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case cleaningStatus = "cleaning_status"
        case updatedBy = "updated_by"
        case updatedAt = "updated_at"
    }
}

struct RoomFlagsUpdate: Codable {
    let flags: [String]
    let updatedBy: UUID?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case flags
        case updatedBy = "updated_by"
        case updatedAt = "updated_at"
    }
}

struct RoomBatchUpdate: Codable {
    let occupancyStatus: String?
    let cleaningStatus: String?
    let flags: [String]?
    let notes: String?
    let updatedBy: UUID?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case occupancyStatus = "occupancy_status"
        case cleaningStatus = "cleaning_status"
        case flags
        case notes
        case updatedBy = "updated_by"
        case updatedAt = "updated_at"
    }
}