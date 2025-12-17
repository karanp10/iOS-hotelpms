import Foundation
import SwiftUI

@MainActor
final class HousekeepingQueueViewModel: ObservableObject {

    // MARK: - Dependencies
    private let serviceManager: ServiceManager
    private let hotelId: UUID
    private var allRooms: [Room] = []

    // MARK: - Published Properties

    /// Rooms currently actionable for housekeeping (not ready)
    @Published var displayedRooms: [Room] = []

    /// Loading state
    @Published var isLoading = false

    /// Error message
    @Published var error: String?

    /// Selected floor filter (nil = all)
    @Published var selectedFloor: Int? {
        didSet { applyFilters() }
    }

    /// Available floors derived from loaded rooms
    @Published var availableFloors: [Int] = []

    /// Per-room note counts
    @Published var noteCounts: [UUID: Int] = [:]
    @Published var activeNotes: [RoomNote] = []
    @Published var isLoadingNotes = false
    @Published var notesError: String?

    // MARK: - Toast & Undo State
    @Published var showingToast = false
    @Published var toastMessage = ""
    @Published var roomsInUndoMode: Set<UUID> = []
    @Published var undoActions: [UUID: () -> Void] = [:]

    // MARK: - Computed Properties

    /// Total number of rooms in queue
    var queueCount: Int {
        displayedRooms.filter { $0.cleaningStatus == .dirty || $0.occupancyStatus == .checkedOut }.count
    }

    /// Total number of rooms in progress
    var inProgressCount: Int {
        displayedRooms.filter { $0.cleaningStatus == .cleaningInProgress }.count
    }

    /// Check if queue is empty
    var isQueueEmpty: Bool {
        displayedRooms.isEmpty
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
            let fetchedRooms = try await serviceManager.roomService.getRooms(hotelId: hotelId)
            allRooms = fetchedRooms
            availableFloors = Array(Set(fetchedRooms.map { $0.floorNumber })).sorted()
            if selectedFloor == nil, let firstFloor = availableFloors.first {
                selectedFloor = firstFloor
            }

            applyFilters()
            await loadNoteCounts(for: displayedRooms)

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

            // Optimistically update local state
            if let index = allRooms.firstIndex(where: { $0.id == roomId }) {
                let existing = allRooms[index]
                let previousStatus = existing.cleaningStatus
                allRooms[index] = Room(
                    id: existing.id,
                    hotelId: existing.hotelId,
                    roomNumber: existing.roomNumber,
                    floorNumber: existing.floorNumber,
                    occupancyStatus: existing.occupancyStatus,
                    cleaningStatus: .cleaningInProgress,
                    flags: existing.flags,
                    notes: existing.notes,
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
                applyFilters()
                // Audit log
                try? await serviceManager.roomHistoryService.logCleaningChange(
                    roomId: roomId,
                    actorId: userId,
                    from: previousStatus,
                    to: .cleaningInProgress
                )
            }
        } catch {
            self.error = "Failed to start cleaning: \(error.localizedDescription)"
        }
    }

    /// Mark room as ready (cleaning_in_progress → ready) with undo support
    func markReady(roomId: UUID) async {
        guard let userId = serviceManager.currentUserId else {
            error = "User not authenticated"
            return
        }

        guard let roomIndex = allRooms.firstIndex(where: { $0.id == roomId }) else {
            return
        }

        let room = allRooms[roomIndex]
        let previousStatus = room.cleaningStatus

        // Optimistic update - change status to ready
        let updatedRoom = Room(
            id: room.id,
            hotelId: room.hotelId,
            roomNumber: room.roomNumber,
            floorNumber: room.floorNumber,
            occupancyStatus: room.occupancyStatus,
            cleaningStatus: .ready,
            flags: room.flags,
            notes: room.notes,
            createdAt: room.createdAt,
            updatedAt: Date()
        )
        allRooms[roomIndex] = updatedRoom

        // DON'T filter yet - keep room visible during undo window
        // applyFilters() will be called by completeMarkReady() after 5s

        // Show toast notification
        toastMessage = "Room \(room.displayNumber) marked as ready ✨"
        showToast()

        // Setup per-room undo functionality
        roomsInUndoMode.insert(roomId)
        undoActions[roomId] = {
            self.undoMarkReady(roomId: roomId, previousStatus: previousStatus)
        }

        // Set timer to auto-complete after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.roomsInUndoMode.contains(roomId) {
                self.completeMarkReady(roomId: roomId)
            }
        }

        // Persist to database asynchronously
        do {
            try await serviceManager.roomService.updateCleaningStatus(
                roomId: roomId,
                newStatus: .ready,
                updatedBy: userId
            )

            // Audit log
            try? await serviceManager.roomHistoryService.logCleaningChange(
                roomId: roomId,
                actorId: userId,
                from: previousStatus,
                to: .ready
            )
        } catch {
            // Revert optimistic update on error
            allRooms[roomIndex] = room
            applyFilters()
            self.error = "Failed to mark room ready: \(error.localizedDescription)"

            // Cancel undo since operation failed
            roomsInUndoMode.remove(roomId)
            undoActions.removeValue(forKey: roomId)
        }
    }

    /// Undo mark ready (revert ready → cleaning_in_progress)
    private func undoMarkReady(roomId: UUID, previousStatus: CleaningStatus) {
        // Clean up undo state
        roomsInUndoMode.remove(roomId)
        undoActions.removeValue(forKey: roomId)

        guard let roomIndex = allRooms.firstIndex(where: { $0.id == roomId }) else {
            return
        }

        let room = allRooms[roomIndex]

        // Revert to previous status
        allRooms[roomIndex] = Room(
            id: room.id,
            hotelId: room.hotelId,
            roomNumber: room.roomNumber,
            floorNumber: room.floorNumber,
            occupancyStatus: room.occupancyStatus,
            cleaningStatus: previousStatus,
            flags: room.flags,
            notes: room.notes,
            createdAt: room.createdAt,
            updatedAt: room.updatedAt
        )

        applyFilters()

        // Show toast confirmation
        toastMessage = "Undid mark ready - Room \(room.displayNumber) back to \(previousStatus.displayName) ↶"
        showToast()

        // Persist undo to database
        Task {
            guard let userId = serviceManager.currentUserId else { return }

            do {
                try await serviceManager.roomService.updateCleaningStatus(
                    roomId: roomId,
                    newStatus: previousStatus,
                    updatedBy: userId
                )

                // Audit log
                try? await serviceManager.roomHistoryService.logCleaningChange(
                    roomId: roomId,
                    actorId: userId,
                    from: .ready,
                    to: previousStatus
                )
            } catch {
                self.error = "Failed to undo: \(error.localizedDescription)"
            }
        }
    }

    /// Refresh the queue
    func refresh() async {
        await loadQueue()
    }

    // MARK: - Notes

    @discardableResult
    func addNote(roomId: UUID, body: String) async -> Bool {
        guard let userId = serviceManager.currentUserId else {
            error = "User not authenticated"
            return false
        }

        do {
            try await serviceManager.notesService.createNote(
                roomId: roomId,
                authorId: userId,
                body: body
            )
            await loadNoteCounts(for: allRooms.filter { $0.id == roomId })
            if let target = activeNotes.first?.roomId, target == roomId {
                await loadNotesForRoom(roomId: roomId)
            }
            return true
        } catch {
            self.error = "Failed to add note: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Filtering

    private func applyFilters() {
        let activeRooms = allRooms.filter { $0.cleaningStatus != .ready }
        displayedRooms = filterRooms(activeRooms)
    }

    private func filterRooms(_ rooms: [Room]) -> [Room] {
        var result = rooms

        if let floor = selectedFloor {
            result = result.filter { $0.floorNumber == floor }
        }

        // Sort by floor then room number for predictable ordering
        result.sort {
            if $0.floorNumber == $1.floorNumber {
                return $0.roomNumber < $1.roomNumber
            }
            return $0.floorNumber < $1.floorNumber
        }

        return result
    }

    // MARK: - Notes Counts

    private func loadNoteCounts(for rooms: [Room]) async {
        guard !rooms.isEmpty else { return }

        await withTaskGroup(of: (UUID, Int)?.self) { group in
            for room in rooms {
                group.addTask { [serviceManager] in
                    do {
                        let notes = try await serviceManager.notesService.getNotesForRoom(roomId: room.id, limit: 200)
                        return (room.id, notes.count)
                    } catch {
                        return nil
                    }
                }
            }

            var updatedCounts = noteCounts

            for await result in group {
                if let (roomId, count) = result {
                    updatedCounts[roomId] = count
                }
            }

            await MainActor.run {
                noteCounts = updatedCounts
            }
        }
    }

    // MARK: - Notes Loading

    func loadNotesForRoom(roomId: UUID) async {
        isLoadingNotes = true
        notesError = nil
        do {
            let notes = try await serviceManager.notesService.getNotesForRoom(roomId: roomId, limit: 200)
            await MainActor.run {
                activeNotes = notes
                isLoadingNotes = false
            }
        } catch {
            await MainActor.run {
                notesError = "Failed to load notes: \(error.localizedDescription)"
                activeNotes = []
                isLoadingNotes = false
            }
        }
    }

    // MARK: - Toast & Undo Management

    func showToast() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showingToast = false
            }
        }
    }

    func executeUndo(roomId: UUID) {
        undoActions[roomId]?()
    }

    private func completeMarkReady(roomId: UUID) {
        // Clean up undo state and filter out ready rooms after undo window expires
        roomsInUndoMode.remove(roomId)
        undoActions.removeValue(forKey: roomId)
        applyFilters()
    }
}
