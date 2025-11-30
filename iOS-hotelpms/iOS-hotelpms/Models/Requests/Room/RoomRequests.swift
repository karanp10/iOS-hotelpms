import Foundation

// MARK: - Room Request Models

struct CreateRoomRequest: Codable {
    let hotelId: UUID
    let roomNumber: Int
    let floorNumber: Int
    let occupancyStatus: String
    let cleaningStatus: String
    let flags: [String]
    let updatedBy: UUID

    enum CodingKeys: String, CodingKey {
        case hotelId = "hotel_id"
        case roomNumber = "room_number"
        case floorNumber = "floor_number"
        case occupancyStatus = "occupancy_status"
        case cleaningStatus = "cleaning_status"
        case flags
        case updatedBy = "updated_by"
    }

    init(
        hotelId: UUID,
        roomNumber: Int,
        floorNumber: Int,
        occupancyStatus: String = "vacant",
        cleaningStatus: String = "dirty",
        flags: [String] = [],
        updatedBy: UUID
    ) {
        self.hotelId = hotelId
        self.roomNumber = roomNumber
        self.floorNumber = floorNumber
        self.occupancyStatus = occupancyStatus
        self.cleaningStatus = cleaningStatus
        self.flags = flags
        self.updatedBy = updatedBy
    }

    init(room: Room, updatedBy: UUID) {
        self.hotelId = room.hotelId
        self.roomNumber = room.roomNumber
        self.floorNumber = room.floorNumber
        self.occupancyStatus = room.occupancyStatus.rawValue
        self.cleaningStatus = room.cleaningStatus.rawValue
        self.flags = room.flags.map { $0.rawValue }
        self.updatedBy = updatedBy
    }
}