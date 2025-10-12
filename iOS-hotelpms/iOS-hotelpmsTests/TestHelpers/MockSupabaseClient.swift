import Foundation
@testable import iOS_hotelpms

class MockSupabaseClient {
    
    // MARK: - Mock Data
    var mockRooms: [Room] = []
    var mockHotels: [Hotel] = []
    var mockProfiles: [Profile] = []
    
    // MARK: - Call Tracking
    var getFromCalled = false
    var insertCalled = false
    var updateCalled = false
    var deleteCalled = false
    var selectCalled = false
    var eqCalled = false
    var orderCalled = false
    var executeCalled = false
    
    // MARK: - Last Operation Tracking
    var lastTableName: String?
    var lastSelectFields: String?
    var lastInsertData: Any?
    var lastUpdateValues: [String: Any] = [:]
    var lastEqField: String?
    var lastEqValue: Any?
    var lastOrderField: String?
    var lastOrderAscending: Bool = true
    
    // MARK: - Error Simulation
    var shouldThrowError = false
    var errorToThrow: Error = TestData.TestError.networkFailure
    
    // MARK: - Response Simulation
    var responseDelay: TimeInterval = 0.0
    
    // MARK: - Mock Query Builder
    
    func from(_ table: String) -> MockQueryBuilder {
        lastTableName = table
        getFromCalled = true
        return MockQueryBuilder(client: self, table: table)
    }
}

class MockQueryBuilder {
    let client: MockSupabaseClient
    let table: String
    
    private var selectFields: String = "*"
    private var whereConditions: [(field: String, value: Any)] = []
    private var orderConditions: [(field: String, ascending: Bool)] = []
    private var insertData: Any?
    private var updateData: [String: Any] = [:]
    
    init(client: MockSupabaseClient, table: String) {
        self.client = client
        self.table = table
    }
    
    func select(_ fields: String = "*") -> MockQueryBuilder {
        client.selectCalled = true
        client.lastSelectFields = fields
        selectFields = fields
        return self
    }
    
    func insert<T: Encodable>(_ data: T) -> MockQueryBuilder {
        client.insertCalled = true
        client.lastInsertData = data
        insertData = data
        return self
    }
    
    func update<T: Encodable>(_ values: T) -> MockQueryBuilder {
        client.updateCalled = true
        // For testing purposes, we'll serialize to dictionary
        if let data = try? JSONEncoder().encode(values),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            client.lastUpdateValues = dict
        }
        updateData = values as! [String : Any]
        return self
    }
    
    func eq(_ field: String, value: Any) -> MockQueryBuilder {
        client.eqCalled = true
        client.lastEqField = field
        client.lastEqValue = value
        whereConditions.append((field: field, value: value))
        return self
    }
    
    func order(_ field: String, ascending: Bool = true) -> MockQueryBuilder {
        client.orderCalled = true
        client.lastOrderField = field
        client.lastOrderAscending = ascending
        orderConditions.append((field: field, ascending: ascending))
        return self
    }
    
    func delete() -> MockQueryBuilder {
        client.deleteCalled = true
        return self
    }
    
    func limit(_ count: Int) -> MockQueryBuilder {
        return self
    }
    
    func ilike(_ field: String, pattern: String) -> MockQueryBuilder {
        return self
    }
    
    func filter(_ field: String, operator op: FilterOperator, value: Any) -> MockQueryBuilder {
        // Treat filter same as eq for testing purposes
        client.eqCalled = true
        client.lastEqField = field
        client.lastEqValue = value
        whereConditions.append((field: field, value: value))
        return self
    }
    
    func execute() async throws -> MockResponse {
        client.executeCalled = true
        
        if client.shouldThrowError {
            throw client.errorToThrow
        }
        
        if client.responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(client.responseDelay * 1_000_000_000))
        }
        
        return MockResponse(client: client, table: table)
    }
}

struct MockResponse {
    let client: MockSupabaseClient
    let table: String
    
    var value: Any {
        get throws {
            switch table {
            case "rooms":
                return client.mockRooms
            case "hotels":
                return client.mockHotels
            case "profiles":
                return client.mockProfiles
            default:
                return []
            }
        }
    }
}

// MARK: - Mock Room Service

class MockRoomService {
    
    // MARK: - Mock Data
    var mockRooms: [Room] = []
    
    // MARK: - Call Tracking
    var getRoomsCalled = false
    var updateOccupancyStatusCalled = false
    var updateCleaningStatusCalled = false
    var toggleFlagCalled = false
    var createRoomCalled = false
    
    // MARK: - Last Operation Tracking
    var lastHotelId: UUID?
    var lastRoomId: UUID?
    var lastOccupancyStatus: OccupancyStatus?
    var lastCleaningStatus: CleaningStatus?
    var lastFlag: RoomFlag?
    var lastUpdatedBy: UUID?
    
    // MARK: - Error Simulation
    var shouldThrowError = false
    var shouldDelay = false
    var errorToThrow: Error = TestData.TestError.networkFailure
    
    // MARK: - Service Methods
    
    func getRooms(hotelId: UUID) async throws -> [Room] {
        getRoomsCalled = true
        lastHotelId = hotelId
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if shouldDelay {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return mockRooms.filter { $0.hotelId == hotelId }
    }
    
    func updateOccupancyStatus(roomId: UUID, newStatus: OccupancyStatus, updatedBy: UUID?) async throws {
        updateOccupancyStatusCalled = true
        lastRoomId = roomId
        lastOccupancyStatus = newStatus
        lastUpdatedBy = updatedBy
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Update mock data
        if let index = mockRooms.firstIndex(where: { $0.id == roomId }) {
            let room = mockRooms[index]
            mockRooms[index] = Room(
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
    }
    
    func updateCleaningStatus(roomId: UUID, newStatus: CleaningStatus, updatedBy: UUID?) async throws {
        updateCleaningStatusCalled = true
        lastRoomId = roomId
        lastCleaningStatus = newStatus
        lastUpdatedBy = updatedBy
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Update mock data
        if let index = mockRooms.firstIndex(where: { $0.id == roomId }) {
            let room = mockRooms[index]
            mockRooms[index] = Room(
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
    }
    
    func toggleFlag(roomId: UUID, flag: RoomFlag, updatedBy: UUID?) async throws {
        toggleFlagCalled = true
        lastRoomId = roomId
        lastFlag = flag
        lastUpdatedBy = updatedBy
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Update mock data
        if let index = mockRooms.firstIndex(where: { $0.id == roomId }) {
            let room = mockRooms[index]
            var newFlags = room.flags
            
            if newFlags.contains(flag) {
                newFlags.removeAll { $0 == flag }
            } else {
                newFlags.append(flag)
            }
            
            mockRooms[index] = Room(
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
    }
    
    func createRoom(_ request: CreateRoomRequest) async throws {
        createRoomCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Add to mock data (simplified)
        let newRoom = Room(
            hotelId: request.hotelId,
            roomNumber: request.roomNumber,
            floorNumber: request.floorNumber,
            occupancyStatus: OccupancyStatus(rawValue: request.occupancyStatus) ?? .vacant,
            cleaningStatus: CleaningStatus(rawValue: request.cleaningStatus) ?? .dirty,
            flags: request.flags.compactMap { RoomFlag(rawValue: $0) }
        )
        mockRooms.append(newRoom)
    }
}

// MARK: - Supporting Enums

enum FilterOperator {
    case eq
    case neq
    case gt
    case gte
    case lt
    case lte
}
