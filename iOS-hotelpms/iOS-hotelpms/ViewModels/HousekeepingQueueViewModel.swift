import Foundation
import SwiftUI

@MainActor
final class HousekeepingQueueViewModel: ObservableObject {

    // MARK: - Dependencies
    private let serviceManager: ServiceManager
    private let hotelId: UUID

    // MARK: - Published Properties

    /// Queued rooms (dirty, not in-progress) sorted by priority
    @Published var queuedRooms: [Room] = []

    /// Rooms currently being cleaned
    @Published var inProgressRooms: [Room] = []

    /// Loading state
    @Published var isLoading = false

    /// Error message
    @Published var error: String?

    // MARK: - Computed Properties

    /// Total number of rooms in queue
    var queueCount: Int {
        queuedRooms.count
    }

    /// Total number of rooms in progress
    var inProgressCount: Int {
        inProgressRooms.count
    }

    /// Check if queue is empty
    var isQueueEmpty: Bool {
        queuedRooms.isEmpty && inProgressRooms.isEmpty
    }

    // MARK: - Initialization

    init(serviceManager: ServiceManager = .shared, hotelId: UUID) {
        self.serviceManager = serviceManager
        self.hotelId = hotelId
    }

    // MARK: - Intent Methods

    /// Load queued and in-progress rooms
    func loadQueue() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let allRooms = try await serviceManager.roomService.getRooms(hotelId: hotelId)

            // Queued rooms: dirty or checked_out, sorted by priority (checked_out first)
            queuedRooms = allRooms
                .filter { room in
                    room.cleaningStatus == .dirty || room.occupancyStatus == .checkedOut
                }
                .sorted { $0.cleaningPriority > $1.cleaningPriority }

            // In-progress rooms: currently being cleaned
            inProgressRooms = allRooms
                .filter { $0.cleaningStatus == .cleaningInProgress }
                .sorted { $0.roomNumber < $1.roomNumber }

        } catch {
            self.error = "Failed to load queue: \(error.localizedDescription)"
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

            // Optimistically move room from queued to in-progress
            if let index = queuedRooms.firstIndex(where: { $0.id == roomId }) {
                var updatedRoom = queuedRooms[index]
                queuedRooms.remove(at: index)

                // Create updated room
                let newRoom = Room(
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

                inProgressRooms.insert(newRoom, at: 0)
                inProgressRooms.sort { $0.roomNumber < $1.roomNumber }
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

            // Optimistically remove room from in-progress
            if let index = inProgressRooms.firstIndex(where: { $0.id == roomId }) {
                inProgressRooms.remove(at: index)
            }
        } catch {
            self.error = "Failed to mark room ready: \(error.localizedDescription)"
        }
    }

    /// Refresh the queue
    func refresh() async {
        await loadQueue()
    }
}
