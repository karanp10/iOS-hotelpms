import Foundation
import Supabase

/// Repository for room read operations and queries
class RoomRepository {
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }
    
    // MARK: - Room Queries
    
    /// Get all rooms for a specific hotel
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
            throw RoomServiceError.networkError("Failed to get rooms: \(error.localizedDescription)")
        }
    }
    
    /// Get a specific room by ID
    func getRoom(id: UUID) async throws -> Room {
        do {
            let response: [Room] = try await supabaseClient
                .from("rooms")
                .select()
                .eq("id", value: id)
                .execute()
                .value
            
            guard let room = response.first else {
                throw RoomServiceError.roomNotFound
            }
            
            return room
        } catch {
            if error is RoomServiceError {
                throw error
            }
            throw RoomServiceError.networkError("Failed to get room: \(error.localizedDescription)")
        }
    }
    
    /// Get rooms by floor
    func getRoomsByFloor(hotelId: UUID, floor: Int) async throws -> [Room] {
        do {
            let response: [Room] = try await supabaseClient
                .from("rooms")
                .select()
                .eq("hotel_id", value: hotelId)
                .eq("floor_number", value: floor)
                .order("room_number", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomServiceError.networkError("Failed to get rooms by floor: \(error.localizedDescription)")
        }
    }
    
    /// Get rooms by occupancy status
    func getRoomsByOccupancy(hotelId: UUID, status: OccupancyStatus) async throws -> [Room] {
        do {
            let response: [Room] = try await supabaseClient
                .from("rooms")
                .select()
                .eq("hotel_id", value: hotelId)
                .eq("occupancy_status", value: status.rawValue)
                .order("room_number", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomServiceError.networkError("Failed to get rooms by occupancy: \(error.localizedDescription)")
        }
    }
    
    /// Get rooms by cleaning status
    func getRoomsByCleaning(hotelId: UUID, status: CleaningStatus) async throws -> [Room] {
        do {
            let response: [Room] = try await supabaseClient
                .from("rooms")
                .select()
                .eq("hotel_id", value: hotelId)
                .eq("cleaning_status", value: status.rawValue)
                .order("room_number", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomServiceError.networkError("Failed to get rooms by cleaning status: \(error.localizedDescription)")
        }
    }
    
    /// Get rooms with specific flags
    func getRoomsWithFlags(hotelId: UUID, flags: [RoomFlag]) async throws -> [Room] {
        do {
            let flagStrings = flags.map { $0.rawValue }
            let response: [Room] = try await supabaseClient
                .from("rooms")
                .select()
                .eq("hotel_id", value: hotelId)
                .overlaps("flags", value: flagStrings)
                .order("room_number", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomServiceError.networkError("Failed to get rooms with flags: \(error.localizedDescription)")
        }
    }
    
    /// Search rooms by number
    func searchRooms(hotelId: UUID, query: String) async throws -> [Room] {
        do {
            let response: [Room] = try await supabaseClient
                .from("rooms")
                .select()
                .eq("hotel_id", value: hotelId)
                .ilike("room_number", pattern: "%\(query)%")
                .order("room_number", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw RoomServiceError.networkError("Failed to search rooms: \(error.localizedDescription)")
        }
    }
    
    /// Get room statistics for a hotel
    func getRoomStats(hotelId: UUID) async throws -> RoomStats {
        let rooms = try await getRooms(hotelId: hotelId)
        
        let occupancyStats = Dictionary(grouping: rooms, by: { $0.occupancyStatus })
            .mapValues { $0.count }
        let cleaningStats = Dictionary(grouping: rooms, by: { $0.cleaningStatus })
            .mapValues { $0.count }
        
        return RoomStats(
            totalRooms: rooms.count,
            occupancyBreakdown: occupancyStats,
            cleaningBreakdown: cleaningStats,
            flaggedRooms: rooms.filter { !$0.flags.isEmpty }.count
        )
    }
}

// MARK: - Supporting Types

struct RoomStats {
    let totalRooms: Int
    let occupancyBreakdown: [OccupancyStatus: Int]
    let cleaningBreakdown: [CleaningStatus: Int]
    let flaggedRooms: Int
}

enum RoomServiceError: LocalizedError {
    case roomNotFound
    case invalidRoomData
    case networkError(String)
    case updateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .roomNotFound:
            return "Room not found"
        case .invalidRoomData:
            return "Invalid room data provided"
        case .networkError(let message):
            return "Network error: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        }
    }
}