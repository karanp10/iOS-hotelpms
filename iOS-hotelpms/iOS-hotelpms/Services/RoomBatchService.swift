import Foundation
import Supabase

// MARK: - Room Batch Service Errors

enum RoomBatchServiceError: LocalizedError {
    case roomCreationFailed(String)
    case userNotAuthenticated
    case networkError(String)
    case invalidRoomRanges
    case hotelAccessDenied
    
    var errorDescription: String? {
        switch self {
        case .roomCreationFailed(let message):
            return "Failed to create rooms: \(message)"
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidRoomRanges:
            return "Invalid room ranges provided"
        case .hotelAccessDenied:
            return "Access denied to this hotel"
        }
    }
}

// MARK: - Room Batch Service

class RoomBatchService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    /// Creates rooms from user-defined ranges
    func createRooms(hotelId: UUID, ranges: [RoomRange], hotelService: HotelService) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw RoomBatchServiceError.userNotAuthenticated
        }
        
        // Validate that user has access to this hotel
        do {
            let _ = try await hotelService.getHotel(id: hotelId)
        } catch {
            throw RoomBatchServiceError.hotelAccessDenied
        }
        
        // Generate all rooms from ranges
        var roomsToCreate: [CreateRoomRequest] = []
        
        for range in ranges {
            guard range.isValid,
                  let startRoom = Int(range.startRoom),
                  let endRoom = Int(range.endRoom) else {
                continue
            }
            
            for roomNumber in startRoom...endRoom {
                let floorNumber = Room.calculateFloor(from: roomNumber)
                let room = Room(
                    hotelId: hotelId,
                    roomNumber: roomNumber,
                    floorNumber: floorNumber,
                    occupancyStatus: .vacant,
                    cleaningStatus: .dirty,
                    flags: []
                )
                roomsToCreate.append(CreateRoomRequest(room: room))
            }
        }
        
        guard !roomsToCreate.isEmpty else {
            throw RoomBatchServiceError.invalidRoomRanges
        }
        
        // Batch insert rooms
        do {
            let _ = try await supabase
                .from("rooms")
                .insert(roomsToCreate)
                .execute()
        } catch {
            throw RoomBatchServiceError.roomCreationFailed(error.localizedDescription)
        }
    }
}