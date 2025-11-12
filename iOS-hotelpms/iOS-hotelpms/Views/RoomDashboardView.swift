import SwiftUI

struct RoomDashboardView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var viewModel: RoomDashboardViewModel
    @StateObject private var serviceManager = ServiceManager.shared
    
    init(hotelId: UUID) {
        self.hotelId = hotelId
        self._viewModel = StateObject(wrappedValue: RoomDashboardViewModel(hotelId: hotelId))
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Pane: Room Grid
                roomListView
                    .frame(width: leftPaneWidth(geometry: geometry))
                
                // Right Pane: Room Detail (conditional)
                if let selectedRoom = viewModel.selectedRoom {
                    Divider()
                    
                    RoomDetailPanel(
                        room: selectedRoom,
                        onClose: viewModel.closeRoomDetail,
                        onOccupancyUpdate: { status in
                            viewModel.updateRoomOccupancy(room: selectedRoom, newStatus: status)
                        },
                        onCleaningUpdate: { status in
                            viewModel.updateRoomCleaning(room: selectedRoom, newStatus: status)
                        },
                        onFlagToggle: { flag in
                            viewModel.toggleRoomFlag(flag, for: selectedRoom)
                        },
                        colorForOccupancy: viewModel.colorForOccupancy,
                        colorForCleaning: viewModel.colorForCleaning,
                        colorForFlag: viewModel.colorForFlag,
                        roomNotes: $viewModel.roomNotes,
                        existingNotes: viewModel.existingNotes,
                        isLoadingNotes: false, // ViewModel now manages its own loading states
                        onSaveNotes: {
                            viewModel.saveNotes(for: selectedRoom)
                        },
                        formatDate: viewModel.formatDate
                    )
                    .frame(width: rightPaneWidth(geometry: geometry))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.selectedRoom != nil)
        }
        .overlay(
            ToastStack(
                showingToast: viewModel.showingToast,
                toastMessage: viewModel.toastMessage,
                showingUndo: viewModel.showingUndo
            )
        )
        .overlay(
            UndoBanner(
                showingUndo: viewModel.showingUndo,
                undoMessage: viewModel.undoMessage,
                onUndo: viewModel.executeUndo
            ), 
            alignment: .bottom
        )
        .navigationBarHidden(true)
        .task {
            // TODO: Replace with proper user session management
            // For now, set the current user ID for development/testing
            serviceManager.setCurrentUser(UUID(uuidString: "a861e91c-2bb2-4274-945d-9a6b6bf3503d"))
            await viewModel.loadData()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("Retry") {
                viewModel.retryLastFailedOperation()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        // ServiceManager no longer handles global errors - ViewModels handle their own errors
    }
    
    // MARK: - Panel Width Calculations
    private func leftPaneWidth(geometry: GeometryProxy) -> CGFloat {
        if viewModel.selectedRoom != nil {
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
                RoomStatsHeader(
                    hotel: viewModel.hotel,
                    filteredRoomsCount: viewModel.filteredRooms.count,
                    totalRoomsCount: viewModel.rooms.count,
                    rooms: viewModel.rooms
                )
                
                // Search and Filters
                RoomFiltersView(
                    searchText: $viewModel.searchText,
                    selectedOccupancyFilter: $viewModel.selectedOccupancyFilter,
                    selectedCleaningFilter: $viewModel.selectedCleaningFilter,
                    selectedFloorFilter: $viewModel.selectedFloorFilter,
                    availableFloors: viewModel.availableFloors,
                    hasActiveFilters: viewModel.hasActiveFilters,
                    onClearFilters: viewModel.clearFilters
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            // Room Grid
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading rooms...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
            } else if viewModel.filteredRooms.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "bed.double")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.rooms.isEmpty ? "No rooms found" : "No rooms match your filters")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if !viewModel.rooms.isEmpty && viewModel.hasActiveFilters {
                        Button("Clear Filters") {
                            viewModel.clearFilters()
                        }
                        .foregroundColor(.blue)
                    }
                }
                Spacer()
            } else {
                RoomGridView(
                    roomsByFloor: viewModel.roomsByFloor,
                    availableFloors: viewModel.availableFloors,
                    selectedRoomId: viewModel.selectedRoomId,
                    selectedRoom: viewModel.selectedRoom,
                    recentNotes: viewModel.recentNotes,
                    onRoomTap: viewModel.selectRoom,
                    onOccupancyTap: viewModel.updateRoomOccupancy,
                    onCleaningTap: viewModel.updateRoomCleaning,
                    nextOccupancyStatus: viewModel.nextOccupancyStatus,
                    nextCleaningStatus: viewModel.nextCleaningStatus
                )
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

#Preview {
    RoomDashboardView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}