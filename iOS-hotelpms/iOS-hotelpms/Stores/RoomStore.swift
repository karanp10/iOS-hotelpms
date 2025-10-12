import Foundation
import Observation

@Observable
class RoomStore {
    
    // MARK: - Published Properties
    var rooms: [Room] = []
    var isLoading = false
    var errorMessage: String?
    var showingError = false
    
    // MARK: - Private Properties
    private let roomService: RoomService
    
    // MARK: - Initialization
    
    init(roomService: RoomService? = nil) {
        self.roomService = roomService ?? RoomService()
    }
    
    // MARK: - Room Loading
    
    @MainActor
    func loadRooms(hotelId: UUID) async {
        isLoading = true
        clearError()
        
        do {
            let fetchedRooms = try await roomService.getRooms(hotelId: hotelId)
            rooms = fetchedRooms
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Room Updates
    
    @MainActor
    func updateOccupancyStatus(roomId: UUID, newStatus: OccupancyStatus, updatedBy: UUID?) async {
        // Optimistic update
        let originalRoom = rooms.first { $0.id == roomId }
        updateRoomLocally(roomId: roomId) { room in
            Room(
                id: room.id,
                hotelId: room.hotelId,
                roomNumber: room.roomNumber,
                floorNumber: room.floorNumber,
                occupancyStatus: newStatus,
                cleaningStatus: room.cleaningStatus,
                flags: room.flags,
                notes: room.notes,
                createdAt: room.createdAt,
                updatedAt: Date()
            )
        }
        
        do {
            try await roomService.updateOccupancyStatus(
                roomId: roomId,
                newStatus: newStatus,
                updatedBy: updatedBy
            )
        } catch {
            // Revert optimistic update on error
            if let originalRoom = originalRoom {
                updateRoomLocally(roomId: roomId) { _ in originalRoom }
            }
            handleError(error)
        }
    }
    
    @MainActor
    func updateCleaningStatus(roomId: UUID, newStatus: CleaningStatus, updatedBy: UUID?) async {
        // Optimistic update
        let originalRoom = rooms.first { $0.id == roomId }
        updateRoomLocally(roomId: roomId) { room in
            Room(
                id: room.id,
                hotelId: room.hotelId,
                roomNumber: room.roomNumber,
                floorNumber: room.floorNumber,
                occupancyStatus: room.occupancyStatus,
                cleaningStatus: newStatus,
                flags: room.flags,
                notes: room.notes,
                createdAt: room.createdAt,
                updatedAt: Date()
            )
        }
        
        do {
            try await roomService.updateCleaningStatus(
                roomId: roomId,
                newStatus: newStatus,
                updatedBy: updatedBy
            )
        } catch {
            // Revert optimistic update on error
            if let originalRoom = originalRoom {
                updateRoomLocally(roomId: roomId) { _ in originalRoom }
            }
            handleError(error)
        }
    }
    
    @MainActor
    func toggleFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID?) async {
        // Optimistic update
        let originalRoom = rooms.first { $0.id == roomId }
        updateRoomLocally(roomId: roomId) { room in
            var newFlags = room.flags
            if newFlags.contains(flag) {
                newFlags.removeAll { $0 == flag }
            } else {
                newFlags.append(flag)
            }
            
            return Room(
                id: room.id,
                hotelId: room.hotelId,
                roomNumber: room.roomNumber,
                floorNumber: room.floorNumber,
                occupancyStatus: room.occupancyStatus,
                cleaningStatus: room.cleaningStatus,
                flags: newFlags,
                notes: room.notes,
                createdAt: room.createdAt,
                updatedAt: Date()
            )
        }
        
        do {
            try await roomService.toggleFlag(
                roomId: roomId,
                flag: flag,
                updatedBy: updatedBy
            )
        } catch {
            // Revert optimistic update on error
            if let originalRoom = originalRoom {
                updateRoomLocally(roomId: roomId) { _ in originalRoom }
            }
            handleError(error)
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
    
    // MARK: - Helper Methods
    
    private func updateRoomLocally(roomId: UUID, transform: (Room) -> Room) {
        if let index = rooms.firstIndex(where: { $0.id == roomId }) {
            rooms[index] = transform(rooms[index])
        }
    }
    
    // MARK: - Computed Properties
    
    var hasRooms: Bool {
        !rooms.isEmpty
    }
    
    var roomCount: Int {
        rooms.count
    }
    
    func roomsForFloor(_ floor: Int) -> [Room] {
        rooms.filter { $0.floorNumber == floor }
    }
    
    func roomsWithStatus(_ status: OccupancyStatus) -> [Room] {
        rooms.filter { $0.occupancyStatus == status }
    }
    
    func roomsWithCleaningStatus(_ status: CleaningStatus) -> [Room] {
        rooms.filter { $0.cleaningStatus == status }
    }
    
    func roomsWithFlag(_ flag: RoomFlag) -> [Room] {
        rooms.filter { $0.flags.contains(flag) }
    }
}