import XCTest
@testable import iOS_hotelpms

@MainActor
final class RoomStoreTests: XCTestCase {
    
    var roomStore: RoomStore!
    var mockRoomService: MockRoomService!
    
    override func setUpWithError() throws {
        mockRoomService = MockRoomService()
        roomStore = RoomStore() // Use default service for now
    }
    
    override func tearDownWithError() throws {
        roomStore = nil
        mockRoomService = nil
    }
    
    // MARK: - Loading Tests
    
    func testLoadRooms_CallsRoomService() async throws {
        // Given
        let hotelId = UUID()
        let expectedRooms = TestData.sampleRooms
        mockRoomService.mockRooms = expectedRooms
        
        // When
        await roomStore.loadRooms(hotelId: hotelId)
        
        // Then
        XCTAssertTrue(mockRoomService.getRoomsCalled)
        XCTAssertEqual(mockRoomService.lastHotelId, hotelId)
        XCTAssertEqual(roomStore.rooms.count, expectedRooms.count)
        XCTAssertFalse(roomStore.isLoading)
    }
    
    func testLoadRooms_ShowsLoadingState() async throws {
        // Given
        let hotelId = UUID()
        mockRoomService.shouldDelay = true
        
        // When
        let loadingTask = Task {
            await roomStore.loadRooms(hotelId: hotelId)
        }
        
        // Check loading state immediately
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        XCTAssertTrue(roomStore.isLoading)
        
        // Wait for completion
        await loadingTask.value
        XCTAssertFalse(roomStore.isLoading)
    }
    
    // MARK: - Room Update Tests
    
    func testUpdateRoom_UpdatesLocalState() async throws {
        // Given
        let hotelId = UUID()
        let initialRooms = TestData.sampleRooms
        mockRoomService.mockRooms = initialRooms
        await roomStore.loadRooms(hotelId: hotelId)
        
        let roomToUpdate = initialRooms[0]
        let newStatus = OccupancyStatus.occupied
        
        // When
        await roomStore.updateOccupancyStatus(
            roomId: roomToUpdate.id,
            newStatus: newStatus,
            updatedBy: UUID()
        )
        
        // Then
        XCTAssertTrue(mockRoomService.updateOccupancyStatusCalled)
        let updatedRoom = roomStore.rooms.first { $0.id == roomToUpdate.id }
        XCTAssertEqual(updatedRoom?.occupancyStatus, newStatus)
    }
    
    func testUpdateRoom_ServiceFails_ShowsError() async throws {
        // Given
        let hotelId = UUID()
        mockRoomService.mockRooms = TestData.sampleRooms
        await roomStore.loadRooms(hotelId: hotelId)
        
        let roomId = TestData.sampleRooms[0].id
        mockRoomService.shouldThrowError = true
        
        // When
        await roomStore.updateOccupancyStatus(
            roomId: roomId,
            newStatus: .occupied,
            updatedBy: UUID()
        )
        
        // Then
        XCTAssertNotNil(roomStore.errorMessage)
        XCTAssertTrue(roomStore.showingError)
    }
    
    // MARK: - Cleaning Status Tests
    
    func testUpdateCleaningStatus_UpdatesLocalState() async throws {
        // Given
        let hotelId = UUID()
        mockRoomService.mockRooms = TestData.sampleRooms
        await roomStore.loadRooms(hotelId: hotelId)
        
        let roomId = TestData.sampleRooms[0].id
        let newStatus = CleaningStatus.inspected
        
        // When
        await roomStore.updateCleaningStatus(
            roomId: roomId,
            newStatus: newStatus,
            updatedBy: UUID()
        )
        
        // Then
        XCTAssertTrue(mockRoomService.updateCleaningStatusCalled)
        let updatedRoom = roomStore.rooms.first { $0.id == roomId }
        XCTAssertEqual(updatedRoom?.cleaningStatus, newStatus)
    }
    
    // MARK: - Flag Toggle Tests
    
    func testToggleFlag_UpdatesLocalState() async throws {
        // Given
        let hotelId = UUID()
        mockRoomService.mockRooms = TestData.sampleRooms
        await roomStore.loadRooms(hotelId: hotelId)
        
        let roomId = TestData.sampleRooms[0].id
        let flag = RoomFlag.maintenanceRequired
        
        // When
        await roomStore.toggleFlag(
            roomId: roomId,
            flag: flag,
            updatedBy: UUID()
        )
        
        // Then
        XCTAssertTrue(mockRoomService.toggleFlagCalled)
        let updatedRoom = roomStore.rooms.first { $0.id == roomId }
        XCTAssertTrue(updatedRoom?.flags.contains(flag) == true)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError_ResetsErrorState() {
        // Given
        roomStore.errorMessage = "Test error"
        roomStore.showingError = true
        
        // When
        roomStore.clearError()
        
        // Then
        XCTAssertNil(roomStore.errorMessage)
        XCTAssertFalse(roomStore.showingError)
    }
    
    // MARK: - Optimistic Update Tests
    
    func testOptimisticUpdate_ReturnsOnServiceFailure() async throws {
        // Given
        let hotelId = UUID()
        let originalRooms = TestData.sampleRooms
        mockRoomService.mockRooms = originalRooms
        await roomStore.loadRooms(hotelId: hotelId)
        
        let roomToUpdate = originalRooms[0]
        let originalStatus = roomToUpdate.occupancyStatus
        mockRoomService.shouldThrowError = true
        
        // When
        await roomStore.updateOccupancyStatus(
            roomId: roomToUpdate.id,
            newStatus: .occupied,
            updatedBy: UUID()
        )
        
        // Then - Should revert to original state on error
        let revertedRoom = roomStore.rooms.first { $0.id == roomToUpdate.id }
        XCTAssertEqual(revertedRoom?.occupancyStatus, originalStatus)
        XCTAssertNotNil(roomStore.errorMessage)
    }
}