import Foundation
import SwiftUI

@MainActor
final class HousekeepingBoardViewModel: ObservableObject {

    // MARK: - Dependencies
    private let serviceManager: ServiceManager
    private let hotelId: UUID

    // MARK: - Published Properties

    /// All rooms loaded from the service
    @Published var rooms: [Room] = []

    /// Loading state
    @Published var isLoading = false

    /// Error message
    @Published var error: String?

    /// Search text
    @Published var searchText = "" {
        didSet { applyFilters() }
    }

    /// Selected floor filter (nil = all floors)
    @Published var selectedFloor: Int? {
        didSet { applyFilters() }
    }

    /// Selected cleaning status filter (nil = all statuses)
    @Published var selectedStatus: CleaningStatus? {
        didSet { applyFilters() }
    }

    /// Filtered rooms based on search and filters
    @Published var filteredRooms: [Room] = []

    // MARK: - Computed Properties

    /// Rooms that are dirty and need cleaning
    var dirtyRooms: [Room] {
        filteredRooms
            .filter { $0.cleaningStatus == .dirty || $0.occupancyStatus == .checkedOut }
            .sorted { $0.cleaningPriority > $1.cleaningPriority }
    }

    /// Rooms currently being cleaned
    var inProgressRooms: [Room] {
        filteredRooms
            .filter { $0.cleaningStatus == .cleaningInProgress }
            .sorted { $0.roomNumber < $1.roomNumber }
    }

    /// Rooms that are clean and ready
    var readyRooms: [Room] {
        filteredRooms
            .filter { $0.cleaningStatus == .ready }
            .sorted { $0.roomNumber < $1.roomNumber }
    }

    /// Stats for header display
    var stats: (dirty: Int, inProgress: Int, ready: Int) {
        let allRooms = rooms // Use all rooms for stats, not filtered
        return (
            dirty: allRooms.filter { $0.cleaningStatus == .dirty || $0.occupancyStatus == .checkedOut }.count,
            inProgress: allRooms.filter { $0.cleaningStatus == .cleaningInProgress }.count,
            ready: allRooms.filter { $0.cleaningStatus == .ready }.count
        )
    }

    /// Get unique floors for filter
    var availableFloors: [Int] {
        Array(Set(rooms.map { $0.floorNumber })).sorted()
    }

    // MARK: - Initialization

    init(serviceManager: ServiceManager = .shared, hotelId: UUID) {
        self.serviceManager = serviceManager
        self.hotelId = hotelId
    }

    // MARK: - Intent Methods

    /// Load all rooms for the hotel
    func loadRooms() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let loadedRooms = try await serviceManager.roomService.getRooms(hotelId: hotelId)
            rooms = loadedRooms
            applyFilters()
        } catch {
            self.error = "Failed to load rooms: \(error.localizedDescription)"
        }
    }

    /// Start cleaning a room (dirty → cleaning_in_progress)
    func startCleaning(roomId: UUID) async {
        guard let userId = serviceManager.currentUserId else {
            error = "User not authenticated"
            return
        }

        do {
            try await serviceManager.roomService.updateCleaningStatus(
                roomId: roomId,
                newStatus: .cleaningInProgress,
                updatedBy: userId
            )

            // Optimistically update local state
            if let index = rooms.firstIndex(where: { $0.id == roomId }) {
                var updatedRoom = rooms[index]
                // Create new room with updated status (Room is immutable struct)
                rooms[index] = Room(
                    id: updatedRoom.id,
                    hotelId: updatedRoom.hotelId,
                    roomNumber: updatedRoom.roomNumber,
                    floorNumber: updatedRoom.floorNumber,
                    occupancyStatus: updatedRoom.occupancyStatus,
                    cleaningStatus: .cleaningInProgress,
                    flags: updatedRoom.flags,
                    notes: updatedRoom.notes,
                    createdAt: updatedRoom.createdAt,
                    updatedAt: Date()
                )
                applyFilters()
            }
        } catch {
            self.error = "Failed to start cleaning: \(error.localizedDescription)"
        }
    }

    /// Mark room as ready (cleaning_in_progress → ready)
    func markReady(roomId: UUID) async {
        guard let userId = serviceManager.currentUserId else {
            error = "User not authenticated"
            return
        }

        do {
            try await serviceManager.roomService.updateCleaningStatus(
                roomId: roomId,
                newStatus: .ready,
                updatedBy: userId
            )

            // Optimistically update local state
            if let index = rooms.firstIndex(where: { $0.id == roomId }) {
                var updatedRoom = rooms[index]
                rooms[index] = Room(
                    id: updatedRoom.id,
                    hotelId: updatedRoom.hotelId,
                    roomNumber: updatedRoom.roomNumber,
                    floorNumber: updatedRoom.floorNumber,
                    occupancyStatus: updatedRoom.occupancyStatus,
                    cleaningStatus: .ready,
                    flags: updatedRoom.flags,
                    notes: updatedRoom.notes,
                    createdAt: updatedRoom.createdAt,
                    updatedAt: Date()
                )
                applyFilters()
            }
        } catch {
            self.error = "Failed to mark room ready: \(error.localizedDescription)"
        }
    }

    /// Add a cleaning note to a room
    func addCleaningNote(roomId: UUID, note: String) async {
        guard let userId = serviceManager.currentUserId else {
            error = "User not authenticated"
            return
        }

        do {
            try await serviceManager.notesService.createNote(
                roomId: roomId,
                authorId: userId,
                body: note
            )
        } catch {
            self.error = "Failed to add note: \(error.localizedDescription)"
        }
    }

    /// Apply search and filter criteria
    func applyFilters() {
        var result = rooms

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { room in
                String(room.roomNumber).contains(searchText)
            }
        }

        // Apply floor filter
        if let floor = selectedFloor {
            result = result.filter { $0.floorNumber == floor }
        }

        // Apply status filter
        if let status = selectedStatus {
            result = result.filter { $0.cleaningStatus == status }
        }

        filteredRooms = result
    }

    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedFloor = nil
        selectedStatus = nil
    }
}
