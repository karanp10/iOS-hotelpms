import Foundation

// MARK: - Room Request Models

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