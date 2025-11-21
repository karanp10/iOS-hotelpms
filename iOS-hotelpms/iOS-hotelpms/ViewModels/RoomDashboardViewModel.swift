import Foundation
import SwiftUI

@MainActor
class RoomDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var hotel: Hotel?
    @Published var rooms: [Room] = []
    @Published var recentNotes: [RoomNote] = []
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    // MARK: - Filter Properties
    @Published var searchText = ""
    @Published var selectedOccupancyFilter: OccupancyStatus?
    @Published var selectedCleaningFilter: CleaningStatus?
    @Published var selectedFloorFilter: Int?
    
    // MARK: - Split View State
    @Published var selectedRoomId: UUID?
    @Published var showingDetail = false
    
    // MARK: - Toast & Undo State
    @Published var showingToast = false
    @Published var toastMessage = ""
    @Published var showingUndo = false
    @Published var undoMessage = ""
    @Published var undoAction: (() -> Void)?
    
    // MARK: - Notes State
    @Published var roomNotes: String = ""
    @Published var existingNotes: [RoomNote] = []
    @Published var scrollTargetId: UUID?
    
    // MARK: - Dependencies
    private let hotelId: UUID
    private let serviceManager: ServiceManager
    private var pendingRoomSelection: UUID?
    
    // MARK: - Computed Properties
    var selectedRoom: Room? {
        guard let roomId = selectedRoomId else { return nil }
        return rooms.first { $0.id == roomId }
    }
    
    var filteredRooms: [Room] {
        rooms.filter { room in
            let matchesSearch = searchText.isEmpty || 
                               String(room.roomNumber).contains(searchText)
            
            let matchesOccupancy = selectedOccupancyFilter == nil || 
                                  room.occupancyStatus == selectedOccupancyFilter
            
            let matchesCleaning = selectedCleaningFilter == nil || 
                                 room.cleaningStatus == selectedCleaningFilter
            
            let matchesFloor = selectedFloorFilter == nil || 
                              room.floorNumber == selectedFloorFilter
            
            return matchesSearch && matchesOccupancy && matchesCleaning && matchesFloor
        }
    }
    
    var roomsByFloor: [Int: [Room]] {
        Dictionary(grouping: filteredRooms) { $0.floorNumber }
    }
    
    var availableFloors: [Int] {
        let floors = Set(rooms.map { $0.floorNumber })
        return floors.sorted()
    }
    
    var hasActiveFilters: Bool {
        !searchText.isEmpty || 
        selectedOccupancyFilter != nil || 
        selectedCleaningFilter != nil || 
        selectedFloorFilter != nil
    }
    
    // MARK: - Initialization
    init(
        hotelId: UUID,
        initialRoomId: UUID? = nil,
        serviceManager: ServiceManager = ServiceManager.shared
    ) {
        self.hotelId = hotelId
        self.serviceManager = serviceManager
        self.pendingRoomSelection = initialRoomId
        self.roomNotes = "Add notes about this room..."
    }
    
    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        
        do {
            // Load hotel info, rooms, and recent notes in parallel
            async let hotelTask = serviceManager.hotelService.getHotel(id: hotelId)
            async let roomsTask = serviceManager.roomService.getRooms(hotelId: hotelId)
            async let notesTask = serviceManager.notesService.getRecentNotesForHotel(hotelId: hotelId)
            
            hotel = try await hotelTask
            rooms = try await roomsTask
            recentNotes = try await notesTask
            applyPendingRoomSelection()
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    private func reloadRecentNotes() async {
        do {
            recentNotes = try await serviceManager.notesService.getRecentNotesForHotel(hotelId: hotelId)
        } catch {
            // Silently fail for notes reload - don't show error to user
            print("Failed to reload recent notes: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Filter Management
    func clearFilters() {
        searchText = ""
        selectedOccupancyFilter = nil
        selectedCleaningFilter = nil
        selectedFloorFilter = nil
    }
    
    // MARK: - Room Selection
    func selectRoom(_ room: Room) {
        if selectedRoomId == room.id {
            // Same room tapped, close panel
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedRoomId = nil
                showingDetail = false
            }
        } else {
            // New room selected, update content smoothly
            openRoom(room, shouldScroll: false)
        }
    }
    
    func focusOnRoom(_ roomId: UUID) {
        pendingRoomSelection = roomId
        applyPendingRoomSelection()
    }
    
    func closeRoomDetail() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedRoomId = nil
            showingDetail = false
        }
    }

    private func openRoom(_ room: Room, shouldScroll: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedRoomId = room.id
            showingDetail = true
            roomNotes = "Add notes about this room..."
        }
        loadNotesForRoom(room)
        scrollTargetId = shouldScroll ? room.id : nil
    }
    
    private func applyPendingRoomSelection() {
        guard let pendingRoomSelection,
              let room = rooms.first(where: { $0.id == pendingRoomSelection }) else { return }
        self.pendingRoomSelection = nil
        
        // Clear any active filters to ensure the target room is visible
        clearFilters()
        
        // Open room immediately but delay scroll to allow LazyVGrid to render
        openRoom(room, shouldScroll: false)
        
        // Delay scroll target to ensure LazyVGrid has materialized the room card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.scrollTargetId = room.id
        }
    }
    
    func consumeScrollTarget() {
        scrollTargetId = nil
    }
    
    // MARK: - Room Mutations
    func updateRoomOccupancy(room: Room, newStatus: OccupancyStatus) {
        let previousStatus = room.occupancyStatus
        
        // Optimistic update - update UI immediately
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[index] = Room(
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
        
        // Show toast notification
        toastMessage = "Room \(room.displayNumber) marked as \(newStatus.displayName) ✅"
        showToast()
        
        // Persist to database asynchronously
        Task {
            do {
                guard let userId = serviceManager.currentUserId else {
                    throw ServiceError.userNotAuthenticated
                }
                
                // Update room status
                try await serviceManager.roomService.updateOccupancyStatus(
                    roomId: room.id,
                    newStatus: newStatus,
                    updatedBy: userId
                )
                
                // Create audit trail
                try await serviceManager.roomHistoryService.logOccupancyChange(
                    roomId: room.id,
                    actorId: userId,
                    from: previousStatus,
                    to: newStatus
                )
            } catch {
                // Revert optimistic update on error
                if let index = rooms.firstIndex(where: { $0.id == room.id }) {
                    rooms[index] = Room(
                        id: room.id,
                        hotelId: room.hotelId,
                        roomNumber: room.roomNumber,
                        floorNumber: room.floorNumber,
                        occupancyStatus: previousStatus,
                        cleaningStatus: room.cleaningStatus,
                        flags: room.flags,
                        notes: room.notes,
                        createdAt: room.createdAt,
                        updatedAt: room.updatedAt
                    )
                }
                
                errorMessage = "Failed to update room: \(error.localizedDescription)"
                showingError = true
            }
        }
        
        // Setup undo functionality
        if previousStatus != newStatus {
            undoMessage = "Changed occupancy to \(newStatus.displayName)"
            undoAction = {
                self.updateRoomOccupancyWithoutUndo(room: room, newStatus: previousStatus)
            }
            showUndo()
        }
    }
    
    func updateRoomCleaning(room: Room, newStatus: CleaningStatus) {
        let previousStatus = room.cleaningStatus
        
        // Optimistic update - update UI immediately
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[index] = Room(
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
        
        // Show toast notification
        let emoji = newStatus == .cleaningInProgress ? "🧹" : (newStatus == .ready ? "✨" : "🧽")
        toastMessage = "Room \(room.displayNumber) set to \(newStatus.displayName) \(emoji)"
        showToast()
        
        // Persist to database asynchronously
        Task {
            do {
                guard let userId = serviceManager.currentUserId else {
                    throw ServiceError.userNotAuthenticated
                }
                
                // Update cleaning status
                try await serviceManager.roomService.updateCleaningStatus(
                    roomId: room.id,
                    newStatus: newStatus,
                    updatedBy: userId
                )
                
                // Create audit trail
                try await serviceManager.roomHistoryService.logCleaningChange(
                    roomId: room.id,
                    actorId: userId,
                    from: previousStatus,
                    to: newStatus
                )
            } catch {
                // Revert optimistic update on error
                if let index = rooms.firstIndex(where: { $0.id == room.id }) {
                    rooms[index] = Room(
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
                }
                
                errorMessage = "Failed to update cleaning status: \(error.localizedDescription)"
                showingError = true
            }
        }
        
        // Setup undo functionality
        if previousStatus != newStatus {
            undoMessage = "Changed cleaning to \(newStatus.displayName)"
            undoAction = {
                self.updateRoomCleaningWithoutUndo(room: room, newStatus: previousStatus)
            }
            showUndo()
        }
    }
    
    func toggleRoomFlag(_ flag: RoomFlag, for room: Room) {
        let previousFlags = room.flags
        
        // Calculate new flags
        var newFlags = room.flags
        let isRemoving = newFlags.contains(flag)
        
        if isRemoving {
            newFlags.removeAll { $0 == flag }
            toastMessage = "Removed \(flag.displayName) flag from Room \(room.displayNumber)"
        } else {
            newFlags.append(flag)
            toastMessage = "Added \(flag.displayName) flag to Room \(room.displayNumber)"
        }
        
        // Optimistic update - update UI immediately
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[index] = Room(
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
        
        showToast()
        
        // Persist to database asynchronously
        Task {
            do {
                guard let userId = serviceManager.currentUserId else {
                    throw ServiceError.userNotAuthenticated
                }
                
                // Toggle room flag
                try await serviceManager.roomService.toggleFlag(
                    roomId: room.id,
                    flag: flag,
                    updatedBy: userId
                )
                
                // Create audit trail
                if isRemoving {
                    try await serviceManager.roomHistoryService.logFlagRemoved(
                        roomId: room.id,
                        actorId: userId,
                        flag: flag
                    )
                } else {
                    try await serviceManager.roomHistoryService.logFlagAdded(
                        roomId: room.id,
                        actorId: userId,
                        flag: flag
                    )
                }
            } catch {
                // Revert optimistic update on error
                if let index = rooms.firstIndex(where: { $0.id == room.id }) {
                    rooms[index] = Room(
                        id: room.id,
                        hotelId: room.hotelId,
                        roomNumber: room.roomNumber,
                        floorNumber: room.floorNumber,
                        occupancyStatus: room.occupancyStatus,
                        cleaningStatus: room.cleaningStatus,
                        flags: previousFlags,
                        notes: room.notes,
                        createdAt: room.createdAt,
                        updatedAt: room.updatedAt
                    )
                }
                
                errorMessage = "Failed to toggle flag: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    // MARK: - Undo Operations
    private func updateRoomOccupancyWithoutUndo(room: Room, newStatus: OccupancyStatus) {
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[index] = Room(
                id: room.id,
                hotelId: room.hotelId,
                roomNumber: room.roomNumber,
                floorNumber: room.floorNumber,
                occupancyStatus: newStatus,
                cleaningStatus: room.cleaningStatus,
                flags: room.flags,
                notes: room.notes,
                createdAt: room.createdAt,
                updatedAt: room.updatedAt
            )
        }
        
        toastMessage = "Undid occupancy change - Room \(room.displayNumber) is now \(newStatus.displayName) ↶"
        showToast()
    }
    
    private func updateRoomCleaningWithoutUndo(room: Room, newStatus: CleaningStatus) {
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[index] = Room(
                id: room.id,
                hotelId: room.hotelId,
                roomNumber: room.roomNumber,
                floorNumber: room.floorNumber,
                occupancyStatus: room.occupancyStatus,
                cleaningStatus: newStatus,
                flags: room.flags,
                notes: room.notes,
                createdAt: room.createdAt,
                updatedAt: room.updatedAt
            )
        }
        
        toastMessage = "Undid cleaning change - Room \(room.displayNumber) is now \(newStatus.displayName) ↶"
        showToast()
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
    
    func showUndo() {
        showingUndo = false
        
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
    
    // MARK: - Notes Management
    func loadNotesForRoom(_ room: Room) {
        Task {
            do {
                let notes = try await serviceManager.notesService.getNotesForRoom(roomId: room.id)
                existingNotes = notes
            } catch {
                // Silently fail for notes loading - don't show error to user
                print("Failed to load notes for room: \(error.localizedDescription)")
                existingNotes = []
            }
        }
    }
    
    func saveNotes(for room: Room) {
        let noteText = roomNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !noteText.isEmpty && noteText != "Add notes about this room..." else {
            return
        }
        
        Task {
            do {
                guard let userId = serviceManager.currentUserId else {
                    throw ServiceError.userNotAuthenticated
                }
                
                // Save note through notes service (audit logging handled separately)
                try await serviceManager.notesService.createNote(
                    roomId: room.id,
                    authorId: userId,
                    body: noteText
                )
                
                // Log the note creation for audit trail
                try await serviceManager.roomHistoryService.logNoteAdded(
                    roomId: room.id,
                    actorId: userId,
                    noteText: noteText
                )
                
                toastMessage = "Notes saved for Room \(room.displayNumber) 📝"
                showToast()
                roomNotes = "Add notes about this room..."
                loadNotesForRoom(room)
                await reloadRecentNotes()
            } catch {
                errorMessage = "Failed to save notes: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    // MARK: - Error Handling
    func retryLastFailedOperation() {
        Task {
            await loadData()
        }
    }
    
    // MARK: - Color Helpers
    func colorForOccupancy(_ status: OccupancyStatus) -> Color {
        switch status {
        case .vacant: return .green
        case .assigned: return .gray
        case .occupied: return .blue
        case .stayover: return .orange
        case .checkedOut: return .red
        }
    }
    
    func colorForCleaning(_ status: CleaningStatus) -> Color {
        switch status {
        case .dirty: return .red
        case .cleaningInProgress: return .yellow
        case .ready: return .purple
        }
    }
    
    func colorForFlag(_ flag: RoomFlag) -> Color {
        switch flag {
        case .maintenanceRequired: return .orange
        case .outOfOrder: return .red
        case .outOfService: return .red
        case .dnd: return .purple
        }
    }
    
    // MARK: - Date Formatting
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
                  calendar.isDate(date, inSameDayAs: yesterday) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Status Cycling Logic (Business Logic)
    func nextOccupancyStatus(from current: OccupancyStatus) -> OccupancyStatus {
        switch current {
        case .vacant: return .assigned
        case .assigned: return .occupied
        case .occupied: return .vacant
        case .stayover: return .vacant
        case .checkedOut: return .vacant
        }
    }
    
    func nextCleaningStatus(from current: CleaningStatus) -> CleaningStatus {
        switch current {
        case .dirty: return .cleaningInProgress
        case .cleaningInProgress: return .ready
        case .ready: return .dirty
        }
    }
}
