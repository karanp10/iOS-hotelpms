import Foundation
import Supabase

/// Service for room write operations and mutations
class RoomMutations {
    
    private let supabaseClient: SupabaseClient
    private let repository: RoomRepository
    
    init(supabaseClient: SupabaseClient? = nil, repository: RoomRepository? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
        self.repository = repository ?? RoomRepository(supabaseClient: self.supabaseClient)
    }
    
    // MARK: - Room Creation
    
    func createRoom(_ request: CreateRoomRequest) async throws {
        do {
            let _ = try await supabaseClient
                .from("rooms")
                .insert(request)
                .execute()
        } catch {
            throw RoomServiceError.networkError("Failed to create room: \(error.localizedDescription)")
        }
    }
    
    func createRooms(_ requests: [CreateRoomRequest]) async throws {
        guard !requests.isEmpty else { return }
        
        do {
            let _ = try await supabaseClient
                .from("rooms")
                .insert(requests)
                .execute()
        } catch {
            throw RoomServiceError.networkError("Failed to create rooms: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Room Status Updates
    
    func updateOccupancyStatus(roomId: UUID, newStatus: OccupancyStatus, updatedBy: UUID) async throws {
        let patch = RoomPatch.occupancyUpdate(newStatus, updatedBy: updatedBy)
        try await updateRoom(id: roomId, patch: patch)
    }
    
    func updateCleaningStatus(roomId: UUID, newStatus: CleaningStatus, updatedBy: UUID) async throws {
        let patch = RoomPatch.cleaningUpdate(newStatus, updatedBy: updatedBy)
        try await updateRoom(id: roomId, patch: patch)
    }
    
    // MARK: - Flag Management
    
    func toggleFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID) async throws {
        // Get current room to check existing flags
        let currentRoom = try await repository.getRoom(id: roomId)
        
        // Toggle flag in array
        var newFlags = currentRoom.flags
        if newFlags.contains(flag) {
            newFlags.removeAll { $0 == flag }
        } else {
            newFlags.append(flag)
        }
        
        // Update with new flags
        let patch = RoomPatch.flagsUpdate(newFlags, updatedBy: updatedBy)
        try await updateRoom(id: roomId, patch: patch)
    }
    
    func setFlags(roomId: UUID, flags: [RoomFlag], updatedBy: UUID) async throws {
        let patch = RoomPatch.flagsUpdate(flags, updatedBy: updatedBy)
        try await updateRoom(id: roomId, patch: patch)
    }
    
    func addFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID) async throws {
        let currentRoom = try await repository.getRoom(id: roomId)
        var newFlags = currentRoom.flags
        
        if !newFlags.contains(flag) {
            newFlags.append(flag)
            let patch = RoomPatch.flagsUpdate(newFlags, updatedBy: updatedBy)
            try await updateRoom(id: roomId, patch: patch)
        }
    }
    
    func removeFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID) async throws {
        let currentRoom = try await repository.getRoom(id: roomId)
        let newFlags = currentRoom.flags.filter { $0 != flag }
        
        if newFlags.count != currentRoom.flags.count {
            let patch = RoomPatch.flagsUpdate(newFlags, updatedBy: updatedBy)
            try await updateRoom(id: roomId, patch: patch)
        }
    }
    
    // MARK: - Generic Room Updates
    
    func updateRoom(id: UUID, patch: RoomPatch) async throws {
        guard !patch.isEmpty else {
            return // No updates to apply
        }
        
        do {
            let _ = try await supabaseClient
                .from("rooms")
                .update(patch)
                .eq("id", value: id)
                .execute()
        } catch {
            throw RoomServiceError.updateFailed("Failed to update room: \(error.localizedDescription)")
        }
    }
    
    func updateRoomBatch(updates: [(UUID, RoomPatch)]) async throws {
        guard !updates.isEmpty else { return }
        
        // For batch updates, we could implement a more efficient approach
        // For now, update them sequentially to maintain consistency
        for (roomId, patch) in updates {
            try await updateRoom(id: roomId, patch: patch)
        }
    }
    
    // MARK: - Convenience Update Methods
    
    func updateRoomStatus(
        roomId: UUID,
        occupancy: OccupancyStatus? = nil,
        cleaning: CleaningStatus? = nil,
        flags: [RoomFlag]? = nil,
        updatedBy: UUID
    ) async throws {
        let patch = RoomPatch.builder()
            .updatedBy(updatedBy)
            .updatedAt()
        
        let finalPatch: RoomPatch
        if let occupancy = occupancy {
            finalPatch = patch.occupancy(occupancy).build()
        } else if let cleaning = cleaning {
            finalPatch = patch.cleaning(cleaning).build()
        } else if let flags = flags {
            finalPatch = patch.flags(flags).build()
        } else {
            return // No updates specified
        }
        
        try await updateRoom(id: roomId, patch: finalPatch)
    }
    
    // MARK: - Room Deletion
    
    func deleteRoom(id: UUID) async throws {
        do {
            let _ = try await supabaseClient
                .from("rooms")
                .delete()
                .eq("id", value: id)
                .execute()
        } catch {
            throw RoomServiceError.networkError("Failed to delete room: \(error.localizedDescription)")
        }
    }
}