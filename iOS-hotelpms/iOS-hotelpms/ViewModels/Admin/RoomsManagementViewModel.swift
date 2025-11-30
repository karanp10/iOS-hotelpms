import Foundation
import SwiftUI

@MainActor
class RoomsManagementViewModel: ObservableObject {

    // MARK: - Published Data Properties
    @Published var rooms: [Room] = []

    // MARK: - Published UI State
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingToast = false
    @Published var toastMessage = ""
    @Published var showingUndo = false
    @Published var undoMessage = ""
    @Published var undoAction: (() -> Void)?

    // MARK: - Dependencies
    private let hotelId: UUID
    private let serviceManager: ServiceManager

    // MARK: - Computed Properties
    var roomsByFloor: [Int: [Room]] {
        Dictionary(grouping: rooms) { $0.floorNumber }
    }

    // MARK: - Initialization
    init(
        hotelId: UUID,
        serviceManager: ServiceManager = ServiceManager.shared
    ) {
        self.hotelId = hotelId
        self.serviceManager = serviceManager
    }

    // MARK: - Data Loading
    func loadRooms() async {
        isLoading = true

        do {
            rooms = try await serviceManager.roomService.getRooms(hotelId: hotelId)
        } catch {
            errorMessage = "Failed to load rooms: \(error.localizedDescription)"
            showingError = true
        }

        isLoading = false
    }

    // MARK: - Intent Methods

    /// Add a new room with optimistic update
    func addRoom(roomNumber: Int, floorNumber: Int) {
        guard let userId = serviceManager.currentUserId else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }

        // Create request
        let request = CreateRoomRequest(
            hotelId: hotelId,
            roomNumber: roomNumber,
            floorNumber: floorNumber,
            updatedBy: userId
        )

        // Optimistically create temporary room for UI
        let tempRoom = Room(
            id: UUID(), // Temporary ID
            hotelId: hotelId,
            roomNumber: roomNumber,
            floorNumber: floorNumber,
            occupancyStatus: .vacant,
            cleaningStatus: .dirty,
            flags: [],
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Optimistic update
        rooms.append(tempRoom)

        // Show toast
        toastMessage = "Room \(roomNumber) added"
        showToast()

        // Setup undo
        undoMessage = "Added room \(roomNumber)"
        undoAction = {
            self.rooms.removeAll { $0.id == tempRoom.id }
        }
        showUndo()

        // Persist to database
        Task {
            do {
                let createdRoom = try await serviceManager.roomService.createRoom(request)

                // Replace temp room with real room
                if let index = rooms.firstIndex(where: { $0.id == tempRoom.id }) {
                    rooms[index] = createdRoom
                }

                // Log to history
                try? await serviceManager.roomHistoryService.logRoomCreation(
                    roomId: createdRoom.id,
                    actorId: userId
                )
            } catch {
                // Revert optimistic update
                rooms.removeAll { $0.id == tempRoom.id }

                errorMessage = "Failed to create room: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    /// Delete a room with optimistic update
    func deleteRoom(_ room: Room) {
        guard let userId = serviceManager.currentUserId else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }

        // Store previous state for undo
        let deletedRoom = room
        let previousIndex = rooms.firstIndex(where: { $0.id == room.id })

        // Optimistic update
        rooms.removeAll { $0.id == room.id }

        // Show toast
        toastMessage = "Room \(room.roomNumber) deleted"
        showToast()

        // Setup undo
        undoMessage = "Deleted room \(room.roomNumber)"
        undoAction = {
            if let index = previousIndex {
                self.rooms.insert(deletedRoom, at: index)
            } else {
                self.rooms.append(deletedRoom)
            }
        }
        showUndo()

        // Persist to database
        Task {
            do {
                try await serviceManager.roomService.deleteRoom(id: room.id)

                // Log to history
                try? await serviceManager.roomHistoryService.logRoomDeletion(
                    roomId: room.id,
                    actorId: userId
                )
            } catch {
                // Revert optimistic update
                if let index = previousIndex {
                    rooms.insert(deletedRoom, at: index)
                } else {
                    rooms.append(deletedRoom)
                }

                errorMessage = "Failed to delete room: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    // MARK: - UI Management

    private func showToast() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showingToast = false
            }
        }
    }

    private func showUndo() {
        showingUndo = false // Reset first

        withAnimation(.easeInOut(duration: 0.3)) {
            showingUndo = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showingUndo = false
            }
        }
    }

    func executeUndo() {
        undoAction?()
        withAnimation(.easeInOut(duration: 0.3)) {
            showingUndo = false
        }
    }
}
