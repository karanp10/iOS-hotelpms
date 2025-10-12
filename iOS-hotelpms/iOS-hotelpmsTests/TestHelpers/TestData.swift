import Foundation
@testable import iOS_hotelpms

struct TestData {
    
    // MARK: - Sample Rooms
    
    static let sampleRooms: [Room] = [
        Room(
            id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
            hotelId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174001")!,
            roomNumber: 101,
            floorNumber: 1,
            occupancyStatus: .vacant,
            cleaningStatus: .dirty,
            flags: [],
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Room(
            id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174002")!,
            hotelId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174001")!,
            roomNumber: 102,
            floorNumber: 1,
            occupancyStatus: .occupied,
            cleaningStatus: .inspected,
            flags: [],
            notes: "Guest requested late checkout",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Room(
            id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174003")!,
            hotelId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174001")!,
            roomNumber: 201,
            floorNumber: 2,
            occupancyStatus: .vacant,
            cleaningStatus: .cleaningInProgress,
            flags: [.maintenanceRequired],
            notes: "AC unit needs repair",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Room(
            id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174004")!,
            hotelId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174001")!,
            roomNumber: 202,
            floorNumber: 2,
            occupancyStatus: .assigned,
            cleaningStatus: .inspected,
            flags: [.dnd],
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Room(
            id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174005")!,
            hotelId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174001")!,
            roomNumber: 301,
            floorNumber: 3,
            occupancyStatus: .checkedOut,
            cleaningStatus: .dirty,
            flags: [.outOfOrder, .maintenanceRequired],
            notes: "Multiple issues reported",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    // MARK: - Sample Hotels
    
    static let sampleHotel = Hotel(
        id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174001")!,
        name: "Test Hotel",
        address: "123 Test Street",
        city: "Test City",
        state: "TS",
        zipCode: "12345",
        createdBy: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174006")!,
        createdAt: Date()
    )
    
    // MARK: - Sample Profiles
    
    static let sampleProfile = Profile(
        id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174006")!,
        firstName: "Test",
        lastName: "User",
        email: "test@example.com",
        createdAt: Date()
    )
    
    // MARK: - Room Update Scenarios
    
    struct RoomUpdateScenario {
        let room: Room
        let newOccupancyStatus: OccupancyStatus?
        let newCleaningStatus: CleaningStatus?
        let flagsToToggle: [RoomFlag]
        let expectedOutcome: Room
    }
    
    static let roomUpdateScenarios: [RoomUpdateScenario] = [
        // Scenario: Check in guest
        RoomUpdateScenario(
            room: sampleRooms[0], // Vacant, Dirty
            newOccupancyStatus: .occupied,
            newCleaningStatus: .inspected,
            flagsToToggle: [],
            expectedOutcome: Room(
                id: sampleRooms[0].id,
                hotelId: sampleRooms[0].hotelId,
                roomNumber: sampleRooms[0].roomNumber,
                floorNumber: sampleRooms[0].floorNumber,
                occupancyStatus: .occupied,
                cleaningStatus: .inspected,
                flags: [],
                notes: nil,
                createdAt: sampleRooms[0].createdAt,
                updatedAt: Date()
            )
        ),
        
        // Scenario: Maintenance flag toggle
        RoomUpdateScenario(
            room: sampleRooms[1], // Occupied, Inspected
            newOccupancyStatus: nil,
            newCleaningStatus: nil,
            flagsToToggle: [.maintenanceRequired],
            expectedOutcome: Room(
                id: sampleRooms[1].id,
                hotelId: sampleRooms[1].hotelId,
                roomNumber: sampleRooms[1].roomNumber,
                floorNumber: sampleRooms[1].floorNumber,
                occupancyStatus: .occupied,
                cleaningStatus: .inspected,
                flags: [.maintenanceRequired],
                notes: sampleRooms[1].notes,
                createdAt: sampleRooms[1].createdAt,
                updatedAt: Date()
            )
        )
    ]
    
    // MARK: - Error Scenarios
    
    enum TestError: Error, LocalizedError {
        case networkFailure
        case invalidData
        case unauthorized
        
        var errorDescription: String? {
            switch self {
            case .networkFailure:
                return "Network connection failed"
            case .invalidData:
                return "Invalid data provided"
            case .unauthorized:
                return "User not authorized"
            }
        }
    }
    
    // MARK: - Utility Methods
    
    static func createRoom(
        roomNumber: Int,
        floorNumber: Int = 1,
        occupancyStatus: OccupancyStatus = .vacant,
        cleaningStatus: CleaningStatus = .dirty,
        flags: [RoomFlag] = [],
        notes: String? = nil
    ) -> Room {
        Room(
            hotelId: sampleHotel.id,
            roomNumber: roomNumber,
            floorNumber: floorNumber,
            occupancyStatus: occupancyStatus,
            cleaningStatus: cleaningStatus,
            flags: flags,
            notes: notes
        )
    }
    
    static func createRoomsForFloor(_ floor: Int, count: Int = 10) -> [Room] {
        return (1...count).map { roomIndex in
            let roomNumber = (floor * 100) + roomIndex
            return createRoom(
                roomNumber: roomNumber,
                floorNumber: floor,
                occupancyStatus: OccupancyStatus.allCases.randomElement() ?? .vacant,
                cleaningStatus: CleaningStatus.allCases.randomElement() ?? .dirty
            )
        }
    }
}