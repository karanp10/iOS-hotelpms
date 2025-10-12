import SwiftUI

struct RoomDashboardView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var serviceManager = ServiceManager.shared
    
    @State private var hotel: Hotel?
    @State private var rooms: [Room] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    @State private var selectedOccupancyFilter: OccupancyStatus?
    @State private var selectedCleaningFilter: CleaningStatus?
    @State private var selectedFloorFilter: Int?
    
    // Split view state
    @State private var selectedRoomId: UUID?
    @State private var showingDetail = false
    
    // Computed property to get current room data from rooms array
    private var selectedRoom: Room? {
        guard let roomId = selectedRoomId else { return nil }
        return rooms.first { $0.id == roomId }
    }
    
    // Toast notification state
    @State private var showingToast = false
    @State private var toastMessage = ""
    
    // Success animation state
    @State private var showingSuccessCheck = false
    @State private var successCheckPosition: CGPoint = .zero
    
    // Undo functionality state
    @State private var showingUndo = false
    @State private var undoAction: (() -> Void)?
    @State private var undoMessage = ""
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var filteredRooms: [Room] {
        rooms.filter { room in
            // Search filter
            let matchesSearch = searchText.isEmpty || 
                               String(room.roomNumber).contains(searchText)
            
            // Occupancy filter
            let matchesOccupancy = selectedOccupancyFilter == nil || 
                                  room.occupancyStatus == selectedOccupancyFilter
            
            // Cleaning filter
            let matchesCleaning = selectedCleaningFilter == nil || 
                                 room.cleaningStatus == selectedCleaningFilter
            
            // Floor filter
            let matchesFloor = selectedFloorFilter == nil || 
                              room.floorNumber == selectedFloorFilter
            
            return matchesSearch && matchesOccupancy && matchesCleaning && matchesFloor
        }
    }
    
    private var roomsByFloor: [Int: [Room]] {
        Dictionary(grouping: filteredRooms) { $0.floorNumber }
    }
    
    private var availableFloors: [Int] {
        let floors = Set(rooms.map { $0.floorNumber })
        return floors.sorted()
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Pane: Room Grid
                roomListView
                    .frame(width: leftPaneWidth(geometry: geometry))
                
                // Right Pane: Room Detail (conditional)
                if let selectedRoom = selectedRoom {
                    Divider()
                    
                    roomDetailView(for: selectedRoom)
                        .frame(width: rightPaneWidth(geometry: geometry))
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedRoom != nil)
        }
        .overlay(
            // Toast notification
            toastView
        )
        .overlay(
            // Success animation overlay
            successAnimationView
        )
        .overlay(
            // Undo overlay
            undoView, alignment: .bottom
        )
        .navigationBarHidden(true)
        .task {
            // TODO: Replace with proper user session management
            // For now, set the current user ID for development/testing
            serviceManager.setCurrentUser(UUID(uuidString: "a861e91c-2bb2-4274-945d-9a6b6bf3503d"))
            await loadData()
        }
        .alert("Error", isPresented: $showingError) {
            Button("Retry") {
                retryLastFailedOperation()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        // Global service manager error handling
        .alert("Service Error", isPresented: $serviceManager.showingError) {
            Button("Retry") {
                retryLastFailedOperation()
                serviceManager.clearError()
            }
            Button("Cancel", role: .cancel) {
                serviceManager.clearError()
            }
        } message: {
            Text(serviceManager.lastError?.localizedDescription ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Panel Width Calculations
    private func leftPaneWidth(geometry: GeometryProxy) -> CGFloat {
        if selectedRoom != nil {
            return geometry.size.width * 0.6 // 60% when detail is shown
        } else {
            return geometry.size.width // Full width when no detail
        }
    }
    
    private func rightPaneWidth(geometry: GeometryProxy) -> CGFloat {
        return geometry.size.width * 0.4 // 40% of total width
    }
    
    // MARK: - Left Pane Content
    private var roomListView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                // Hotel Name and Stats
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hotel?.name ?? "Loading...")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("\(filteredRooms.count) of \(rooms.count) rooms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Quick Stats
                    HStack(spacing: 20) {
                        StatCard(
                            title: "Occupied",
                            count: rooms.filter { $0.occupancyStatus == .occupied }.count,
                            color: .green
                        )
                        
                        StatCard(
                            title: "Dirty",
                            count: rooms.filter { $0.cleaningStatus == .dirty }.count,
                            color: .red
                        )
                        
                        StatCard(
                            title: "Flagged",
                            count: rooms.filter { $0.hasFlags }.count,
                            color: .orange
                        )
                    }
                }
                
                // Search and Filters
                HStack(spacing: 12) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search rooms...", text: $searchText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .frame(maxWidth: 200)
                    
                    // Occupancy Filter
                    FilterPicker(
                        title: "Occupancy",
                        selection: $selectedOccupancyFilter,
                        options: OccupancyStatus.allCases,
                        displayName: { $0?.displayName ?? "All" }
                    )
                    
                    // Cleaning Filter
                    FilterPicker(
                        title: "Cleaning",
                        selection: $selectedCleaningFilter,
                        options: CleaningStatus.allCases,
                        displayName: { $0?.displayName ?? "All" }
                    )
                    
                    // Floor Filter
                    FilterPicker(
                        title: "Floor",
                        selection: $selectedFloorFilter,
                        options: availableFloors,
                        displayName: { $0 != nil ? "Floor \($0!)" : "All" }
                    )
                    
                    Spacer()
                    
                    // Clear Filters
                    if hasActiveFilters {
                        Button("Clear Filters") {
                            clearFilters()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            // Room Grid
            if isLoading {
                Spacer()
                ProgressView("Loading rooms...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
            } else if filteredRooms.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "bed.double")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text(rooms.isEmpty ? "No rooms found" : "No rooms match your filters")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if !rooms.isEmpty && hasActiveFilters {
                        Button("Clear Filters") {
                            clearFilters()
                        }
                        .foregroundColor(.blue)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(availableFloors.filter { roomsByFloor[$0] != nil }, id: \.self) { floor in
                            VStack(alignment: .leading, spacing: 16) {
                                // Floor Header
                                HStack {
                                    Text("Floor \(floor)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(roomsByFloor[floor]?.count ?? 0) rooms")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Rooms Grid for this floor
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(roomsByFloor[floor] ?? []) { room in
                                        RoomCard(
                                            room: room,
                                            onTap: {
                                                if selectedRoomId == room.id {
                                                    // Same room tapped, close panel
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        selectedRoomId = nil
                                                        showingDetail = false
                                                    }
                                                } else {
                                                    // New room selected, update content smoothly
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        selectedRoomId = room.id
                                                        showingDetail = true
                                                        // Reset notes for new room
                                                        roomNotes = "Add notes about this room..."
                                                        // Load existing notes for this room
                                                        loadNotesForRoom(room)
                                                    }
                                                }
                                            },
                                            onOccupancyTap: { newStatus in
                                                updateRoomOccupancy(room: room, newStatus: newStatus)
                                            },
                                            onCleaningTap: { newStatus in
                                                updateRoomCleaning(room: room, newStatus: newStatus)
                                            },
                                            isSelected: selectedRoomId == room.id
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
    
    // MARK: - Right Pane Content
    private func roomDetailView(for room: Room) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with close button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Room \(room.displayNumber)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Floor \(room.floorNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedRoomId = nil
                        showingDetail = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Detail content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Current Status Section
                    currentStatusSection(for: room)
                    
                    Divider()
                    
                    // Occupancy Control Section
                    occupancyControlSection(for: room)
                    
                    Divider()
                    
                    // Cleaning Control Section
                    cleaningControlSection(for: room)
                    
                    Divider()
                    
                    // Flag Toggle Section
                    flagToggleSection(for: room)
                    
                    Divider()
                    
                    // Notes Section
                    notesSection(for: room)
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Detail View Sections
    private func currentStatusSection(for room: Room) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                // Occupancy Status
                VStack(alignment: .leading, spacing: 4) {
                    Text("Occupancy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorForOccupancy(room.occupancyStatus))
                            .frame(width: 10, height: 10)
                        
                        Text(room.occupancyStatus.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // Cleaning Status
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cleaning")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: room.cleaningStatus.systemImage)
                            .font(.caption)
                            .foregroundColor(colorForCleaning(room.cleaningStatus))
                        
                        Text(room.cleaningStatus.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Flags if any
            if room.hasFlags {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flags")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(room.flags, id: \.self) { flag in
                            HStack(spacing: 4) {
                                Image(systemName: flag.systemImage)
                                    .font(.system(size: 10))
                                Text(flag.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorForFlag(flag))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
    }
    
    private func occupancyControlSection(for room: Room) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Occupancy")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Segmented control placeholder - will implement proper control
            VStack(spacing: 8) {
                ForEach(OccupancyStatus.allCases, id: \.self) { status in
                    Button(action: {
                        updateRoomOccupancy(room: room, newStatus: status)
                        showSuccessAnimation()
                    }) {
                        HStack {
                            Circle()
                                .fill(colorForOccupancy(status))
                                .frame(width: 12, height: 12)
                            
                            Text(status.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if room.occupancyStatus == status {
                                Image(systemName: "checkmark")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(room.occupancyStatus == status ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func cleaningControlSection(for room: Room) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Cleaning Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(CleaningStatus.allCases, id: \.self) { status in
                    Button(action: {
                        updateRoomCleaning(room: room, newStatus: status)
                        showSuccessAnimation()
                    }) {
                        HStack {
                            Image(systemName: status.systemImage)
                                .font(.subheadline)
                                .foregroundColor(colorForCleaning(status))
                            
                            Text(status.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if room.cleaningStatus == status {
                                Image(systemName: "checkmark")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(room.cleaningStatus == status ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func flagToggleSection(for room: Room) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Toggle Flags")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                FlagChip(
                    flag: .maintenanceRequired,
                    isSelected: room.flags.contains(.maintenanceRequired),
                    onTap: { toggleFlag(.maintenanceRequired, for: room) }
                )
                
                FlagChip(
                    flag: .dnd,
                    isSelected: room.flags.contains(.dnd),
                    onTap: { toggleFlag(.dnd, for: room) }
                )
                
                FlagChip(
                    flag: .outOfOrder,
                    isSelected: room.flags.contains(.outOfOrder),
                    onTap: { toggleFlag(.outOfOrder, for: room) }
                )
                
                FlagChip(
                    flag: .outOfService,
                    isSelected: room.flags.contains(.outOfService),
                    onTap: { toggleFlag(.outOfService, for: room) }
                )
            }
        }
    }
    
    @State private var roomNotes: String = ""
    @State private var existingNotes: [RoomNote] = []
    
    private func notesSection(for room: Room) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if serviceManager.isLoadingNotes {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Existing notes display
            if !existingNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Notes (\(existingNotes.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(existingNotes) { note in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(note.body)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text(formatDate(note.createdAt ?? Date()))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if note.isRecent {
                                        HStack {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 6, height: 6)
                                            
                                            Text("Recent")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
                
                Divider()
            }
            
            // New note input
            VStack(alignment: .leading, spacing: 8) {
                Text("Add New Note")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $roomNotes)
                    .font(.subheadline)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .onAppear {
                        // Initialize with placeholder text
                        if roomNotes.isEmpty {
                            roomNotes = "Add notes about this room..."
                        }
                    }
                
                // Save button
                HStack {
                    Spacer()
                    
                    Button("Save Notes") {
                        saveNotes(for: room)
                    }
                    .disabled(roomNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                             roomNotes == "Add notes about this room...")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(roomNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                               roomNotes == "Add notes about this room..." ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    
    // MARK: - Toast View
    private var toastView: some View {
        VStack {
            if showingToast {
                HStack {
                    Text(toastMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background(Color.black.opacity(0.8))
                .cornerRadius(8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.easeInOut(duration: 0.3), value: showingToast)
            }
            
            Spacer()
        }
        .padding(.top, 50)
    }
    
    // MARK: - Success Animation View
    private var successAnimationView: some View {
        ZStack {
            if showingSuccessCheck {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8)
                    .scaleEffect(showingSuccessCheck ? 1.0 : 0.3)
                    .opacity(showingSuccessCheck ? 1.0 : 0.0)
                    .position(successCheckPosition)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingSuccessCheck)
            }
        }
    }
    
    // MARK: - Undo View
    private var undoView: some View {
        VStack {
            if showingUndo {
                HStack {
                    Text(undoMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Undo") {
                        undoAction?()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingUndo = false
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.9))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 50)
    }
    
    // MARK: - Status Update Functions
    private func updateRoomOccupancy(room: Room, newStatus: OccupancyStatus) {
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
                updatedAt: Date() // Update timestamp
            )
        }
        
        // Show toast notification
        toastMessage = "Room \(room.displayNumber) marked as \(newStatus.displayName) ✅"
        showToast()
        
        // Persist to database asynchronously
        Task {
            let success = await serviceManager.updateRoomOccupancy(
                roomId: room.id,
                newStatus: newStatus,
                previousStatus: previousStatus
            )
            
            if !success {
                // Revert optimistic update on error
                await MainActor.run {
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
                    
                    errorMessage = "Failed to update room: \(serviceManager.lastError?.localizedDescription ?? "Unknown error")"
                    showingError = true
                }
            }
        }
        
        // Setup undo functionality (only if not already undoing)
        if previousStatus != newStatus {
            undoMessage = "Changed occupancy to \(newStatus.displayName)"
            undoAction = {
                self.updateRoomOccupancyWithoutUndo(room: room, newStatus: previousStatus)
            }
            showUndo()
        }
    }
    
    private func updateRoomCleaning(room: Room, newStatus: CleaningStatus) {
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
                updatedAt: Date() // Update timestamp
            )
        }
        
        // Show toast notification
        let emoji = newStatus == .cleaningInProgress ? "🧹" : (newStatus == .inspected ? "✨" : "🧽")
        toastMessage = "Room \(room.displayNumber) set to \(newStatus.displayName) \(emoji)"
        showToast()
        
        // Persist to database asynchronously
        Task {
            let success = await serviceManager.updateRoomCleaning(
                roomId: room.id,
                newStatus: newStatus,
                previousStatus: previousStatus
            )
            
            if !success {
                // Revert optimistic update on error
                await MainActor.run {
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
                    
                    errorMessage = "Failed to update cleaning status: \(serviceManager.lastError?.localizedDescription ?? "Unknown error")"
                    showingError = true
                }
            }
        }
        
        // Setup undo functionality (only if not already undoing)
        if previousStatus != newStatus {
            undoMessage = "Changed cleaning to \(newStatus.displayName)"
            undoAction = {
                self.updateRoomCleaningWithoutUndo(room: room, newStatus: previousStatus)
            }
            showUndo()
        }
    }
    
    private func showToast() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingToast = true
        }
        
        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingToast = false
            }
        }
    }
    
    // MARK: - Update Functions Without Undo (for undo actions)
    private func updateRoomOccupancyWithoutUndo(room: Room, newStatus: OccupancyStatus) {
        // Update the room in the rooms array (UI only for now)
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
        
        // Show toast notification
        toastMessage = "Undid occupancy change - Room \(room.displayNumber) is now \(newStatus.displayName) ↶"
        showToast()
    }
    
    private func updateRoomCleaningWithoutUndo(room: Room, newStatus: CleaningStatus) {
        // Update the room in the rooms array (UI only for now)
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[index] = Room(
                id: room.id,
                hotelId: room.hotelId,
                roomNumber: room.roomNumber,
                floorNumber: room.floorNumber,
                occupancyStatus: room.occupancyStatus,
                cleaningStatus: newStatus,
                flags: room.flags,
                createdAt: room.createdAt,
                updatedAt: room.updatedAt
            )
        }
        
        // Show toast notification  
        toastMessage = "Undid cleaning change - Room \(room.displayNumber) is now \(newStatus.displayName) ↶"
        showToast()
    }
    
    private func showSuccessAnimation() {
        // Position the success check in the center of the right panel
        successCheckPosition = CGPoint(x: UIScreen.main.bounds.width * 0.8, y: UIScreen.main.bounds.height * 0.5)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showingSuccessCheck = true
        }
        
        // Auto-hide after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingSuccessCheck = false
            }
        }
    }
    
    private func showUndo() {
        // Hide any existing undo first
        showingUndo = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingUndo = true
        }
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingUndo = false
            }
        }
    }
    
    // MARK: - Flag Toggle Functions
    private func toggleFlag(_ flag: RoomFlag, for room: Room) {
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
                updatedAt: Date() // Update timestamp
            )
        }
        
        showToast()
        
        // Persist to database asynchronously
        Task {
            let success = await serviceManager.toggleRoomFlag(
                roomId: room.id,
                flag: flag,
                isRemoving: isRemoving
            )
            
            if !success {
                // Revert optimistic update on error
                await MainActor.run {
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
                    
                    errorMessage = "Failed to toggle flag: \(serviceManager.lastError?.localizedDescription ?? "Unknown error")"
                    showingError = true
                }
            }
        }
    }
    
    // MARK: - Notes Functions
    private func loadNotesForRoom(_ room: Room) {
        Task {
            let notes = await serviceManager.loadNotes(for: room.id)
            
            await MainActor.run {
                existingNotes = notes
            }
        }
    }
    
    private func saveNotes(for room: Room) {
        let noteText = roomNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate note content
        guard !noteText.isEmpty && noteText != "Add notes about this room..." else {
            return
        }
        
        Task {
            let success = await serviceManager.saveNote(roomId: room.id, body: noteText)
            
            await MainActor.run {
                if success {
                    toastMessage = "Notes saved for Room \(room.displayNumber) 📝"
                    showToast()
                    // Clear the text area after successful save
                    roomNotes = "Add notes about this room..."
                    // Reload notes to show the new one
                    loadNotesForRoom(room)
                } else {
                    errorMessage = "Failed to save notes: \(serviceManager.lastError?.localizedDescription ?? "Unknown error")"
                    showingError = true
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
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
    
    // MARK: - Color Helper Functions
    private func colorForOccupancy(_ status: OccupancyStatus) -> Color {
        switch status {
        case .vacant: return .green
        case .assigned: return .gray
        case .occupied: return .blue
        case .stayover: return .orange
        case .checkedOut: return .red
        }
    }
    
    private func colorForCleaning(_ status: CleaningStatus) -> Color {
        switch status {
        case .dirty: return .red
        case .cleaningInProgress: return .yellow
        case .inspected: return .purple
        }
    }
    
    private func colorForFlag(_ flag: RoomFlag) -> Color {
        switch flag {
        case .maintenanceRequired: return .orange
        case .outOfOrder: return .red
        case .outOfService: return .red
        case .dnd: return .purple
        }
    }
    
    private var hasActiveFilters: Bool {
        !searchText.isEmpty || 
        selectedOccupancyFilter != nil || 
        selectedCleaningFilter != nil || 
        selectedFloorFilter != nil
    }
    
    private func clearFilters() {
        searchText = ""
        selectedOccupancyFilter = nil
        selectedCleaningFilter = nil
        selectedFloorFilter = nil
    }
    
    @MainActor
    private func loadData() async {
        isLoading = true
        
        do {
            // Load hotel info and rooms in parallel
            async let hotelTask = serviceManager.databaseService.getHotel(id: hotelId)
            async let roomsTask = serviceManager.loadRooms(for: hotelId)
            
            hotel = try await hotelTask
            rooms = await roomsTask
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Retry Logic
    private func retryLastFailedOperation() {
        Task {
            // For now, retry loading data as the most common operation
            // In a more sophisticated implementation, we could track the last failed operation
            await loadData()
        }
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}

struct FilterPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T?
    let options: [T]
    let displayName: (T?) -> String
    
    var body: some View {
        Menu {
            Button(displayName(nil)) {
                selection = nil
            }
            
            Divider()
            
            ForEach(options, id: \.self) { option in
                Button(displayName(option)) {
                    selection = option
                }
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
                Text(displayName(selection))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
}

struct FlagChip: View {
    let flag: RoomFlag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(flagEmoji)
                    .font(.system(size: 16))
                
                Text(flag.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? flagColor.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? flagColor : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? flagColor : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var flagEmoji: String {
        switch flag {
        case .maintenanceRequired: return "🔧"
        case .dnd: return "🌙"
        case .outOfOrder: return "🚫"
        case .outOfService: return "🚫"
        }
    }
    
    private var flagColor: Color {
        switch flag {
        case .maintenanceRequired: return .orange
        case .dnd: return .purple
        case .outOfOrder: return .red
        case .outOfService: return .red
        }
    }
}

#Preview {
    RoomDashboardView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}