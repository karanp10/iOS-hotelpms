import SwiftUI

struct RoomsManagementGrid: View {
    let hotelId: UUID

    @StateObject private var viewModel: RoomsManagementViewModel
    @State private var showingAddSheet = false
    @State private var showingDeleteAlert = false
    @State private var roomToDelete: Room?

    init(hotelId: UUID) {
        self.hotelId = hotelId
        self._viewModel = StateObject(wrappedValue: RoomsManagementViewModel(hotelId: hotelId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Add button
            HStack {
                Text("Rooms")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    showingAddSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Room")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            if viewModel.isLoading {
                loadingView
            } else if viewModel.rooms.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task {
                await viewModel.loadRooms()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRoomSheet { roomNum, floorNum in
                viewModel.addRoom(roomNumber: roomNum, floorNumber: floorNum)
            }
        }
        .alert("Delete Room", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let room = roomToDelete {
                    viewModel.deleteRoom(room)
                }
            }
        } message: {
            if let room = roomToDelete {
                Text("Are you sure you want to delete Room \(room.roomNumber)? This action cannot be undone.")
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .overlay(alignment: .bottom) {
            ZStack {
                // Toast overlay
                if viewModel.showingToast {
                    VStack {
                        Spacer()
                        ToastView(message: viewModel.toastMessage)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, viewModel.showingUndo ? 120 : 70)
                    }
                }

                // Undo banner overlay
                if viewModel.showingUndo {
                    UndoBanner(
                        showingUndo: viewModel.showingUndo,
                        undoMessage: viewModel.undoMessage,
                        onUndo: { viewModel.executeUndo() }
                    )
                }
            }
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Table header
                HStack {
                    Text("Room #")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)

                    Text("Floor")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)

                    Spacer()

                    Text("Actions")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))

                Divider()

                // Rooms list grouped by floor
                ForEach(viewModel.roomsByFloor.keys.sorted(), id: \.self) { floor in
                    if let floorRooms = viewModel.roomsByFloor[floor] {
                        // Floor section header
                        HStack {
                            Text("Floor \(floor)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(floorRooms.count) room\(floorRooms.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(.systemGroupedBackground))

                        ForEach(floorRooms.sorted(by: { $0.roomNumber < $1.roomNumber })) { room in
                            RoomRow(
                                room: room,
                                onDelete: {
                                    roomToDelete = room
                                    showingDeleteAlert = true
                                }
                            )

                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading rooms...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bed.double")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Rooms")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Add rooms to get started with room management.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                showingAddSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Room")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RoomRow: View {
    let room: Room
    let onDelete: () -> Void

    var body: some View {
        HStack {
            // Room number
            Text("\(room.roomNumber)")
                .font(.body)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)

            // Floor
            Text("\(room.floorNumber)")
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            // Actions
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.body)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview("Populated") {
    RoomsManagementGrid(hotelId: UUID())
}

#Preview("Empty") {
    RoomsManagementGrid(hotelId: UUID())
}
