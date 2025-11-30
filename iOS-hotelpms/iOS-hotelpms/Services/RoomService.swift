import Foundation
import Supabase

/// Unified service for room operations, combining repository and mutations with clean separation of concerns.
/// Uses generic patch helpers to reduce boilerplate and improve maintainability.
class RoomService {
    
    // MARK: - Dependencies
    private let repository: RoomRepository
    private let mutations: RoomMutations
    
    init(supabaseClient: SupabaseClient? = nil) {
        let client = supabaseClient ?? SupabaseManager.shared.client
        self.repository = RoomRepository(supabaseClient: client)
        self.mutations = RoomMutations(supabaseClient: client, repository: self.repository)
    }
    
    // MARK: - Repository Methods (Read Operations)
    
    /// Get all rooms for a hotel
    func getRooms(hotelId: UUID) async throws -> [Room] {
        return try await repository.getRooms(hotelId: hotelId)
    }
    
    /// Get a specific room by ID
    func getRoom(id: UUID) async throws -> Room {
        return try await repository.getRoom(id: id)
    }
    
    /// Get rooms by floor
    func getRoomsByFloor(hotelId: UUID, floor: Int) async throws -> [Room] {
        return try await repository.getRoomsByFloor(hotelId: hotelId, floor: floor)
    }
    
    /// Get rooms by occupancy status
    func getRoomsByOccupancy(hotelId: UUID, status: OccupancyStatus) async throws -> [Room] {
        return try await repository.getRoomsByOccupancy(hotelId: hotelId, status: status)
    }
    
    /// Get rooms by cleaning status
    func getRoomsByCleaning(hotelId: UUID, status: CleaningStatus) async throws -> [Room] {
        return try await repository.getRoomsByCleaning(hotelId: hotelId, status: status)
    }
    
    /// Get rooms with specific flags
    func getRoomsWithFlags(hotelId: UUID, flags: [RoomFlag]) async throws -> [Room] {
        return try await repository.getRoomsWithFlags(hotelId: hotelId, flags: flags)
    }
    
    /// Search rooms by number
    func searchRooms(hotelId: UUID, query: String) async throws -> [Room] {
        return try await repository.searchRooms(hotelId: hotelId, query: query)
    }
    
    /// Get room statistics for a hotel
    func getRoomStats(hotelId: UUID) async throws -> RoomStats {
        return try await repository.getRoomStats(hotelId: hotelId)
    }
    
    // MARK: - Mutation Methods (Write Operations)

    /// Create a single room
    func createRoom(_ request: CreateRoomRequest) async throws -> Room {
        return try await mutations.createRoom(request)
    }
    
    /// Create multiple rooms
    func createRooms(_ requests: [CreateRoomRequest]) async throws {
        return try await mutations.createRooms(requests)
    }
    
    /// Update occupancy status
    func updateOccupancyStatus(roomId: UUID, newStatus: OccupancyStatus, updatedBy: UUID) async throws {
        return try await mutations.updateOccupancyStatus(roomId: roomId, newStatus: newStatus, updatedBy: updatedBy)
    }
    
    /// Update cleaning status
    func updateCleaningStatus(roomId: UUID, newStatus: CleaningStatus, updatedBy: UUID) async throws {
        return try await mutations.updateCleaningStatus(roomId: roomId, newStatus: newStatus, updatedBy: updatedBy)
    }
    
    /// Toggle a room flag
    func toggleFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID) async throws {
        return try await mutations.toggleFlag(roomId: roomId, flag: flag, updatedBy: updatedBy)
    }
    
    /// Set room flags (replaces all existing flags)
    func setFlags(roomId: UUID, flags: [RoomFlag], updatedBy: UUID) async throws {
        return try await mutations.setFlags(roomId: roomId, flags: flags, updatedBy: updatedBy)
    }
    
    /// Add a single flag to room
    func addFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID) async throws {
        return try await mutations.addFlag(roomId: roomId, flag: flag, updatedBy: updatedBy)
    }
    
    /// Remove a single flag from room
    func removeFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID) async throws {
        return try await mutations.removeFlag(roomId: roomId, flag: flag, updatedBy: updatedBy)
    }
    
    /// Generic room update using patch
    func updateRoom(id: UUID, patch: RoomPatch) async throws {
        return try await mutations.updateRoom(id: id, patch: patch)
    }
    
    /// Update room with multiple changes
    func updateRoomStatus(
        roomId: UUID,
        occupancy: OccupancyStatus? = nil,
        cleaning: CleaningStatus? = nil,
        flags: [RoomFlag]? = nil,
        updatedBy: UUID
    ) async throws {
        return try await mutations.updateRoomStatus(
            roomId: roomId,
            occupancy: occupancy,
            cleaning: cleaning,
            flags: flags,
            updatedBy: updatedBy
        )
    }
    
    /// Batch update multiple rooms
    func updateRoomBatch(updates: [(UUID, RoomPatch)]) async throws {
        return try await mutations.updateRoomBatch(updates: updates)
    }
    
    /// Delete a room
    func deleteRoom(id: UUID) async throws {
        return try await mutations.deleteRoom(id: id)
    }
    
    // MARK: - Legacy Support (Backward Compatibility)
    
    @available(*, deprecated, message: "Use updateOccupancyStatus with required updatedBy parameter")
    func updateOccupancyStatus(roomId: UUID, newStatus: OccupancyStatus, updatedBy: UUID?) async throws {
        guard let userId = updatedBy else {
            throw RoomServiceError.invalidRoomData
        }
        try await updateOccupancyStatus(roomId: roomId, newStatus: newStatus, updatedBy: userId)
    }
    
    @available(*, deprecated, message: "Use updateCleaningStatus with required updatedBy parameter")
    func updateCleaningStatus(roomId: UUID, newStatus: CleaningStatus, updatedBy: UUID?) async throws {
        guard let userId = updatedBy else {
            throw RoomServiceError.invalidRoomData
        }
        try await updateCleaningStatus(roomId: roomId, newStatus: newStatus, updatedBy: userId)
    }
    
    @available(*, deprecated, message: "Use toggleFlag with required updatedBy parameter")
    func toggleFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID?) async throws {
        guard let userId = updatedBy else {
            throw RoomServiceError.invalidRoomData
        }
        try await toggleFlag(roomId: roomId, flag: flag, updatedBy: userId)
    }
}