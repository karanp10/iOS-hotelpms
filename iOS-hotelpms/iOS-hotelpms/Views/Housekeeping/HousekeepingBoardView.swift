import SwiftUI

struct HousekeepingBoardView: View {
    @StateObject private var viewModel: HousekeepingBoardViewModel

    init(hotelId: UUID) {
        _viewModel = StateObject(wrappedValue: HousekeepingBoardViewModel(hotelId: hotelId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stats Header
            CleaningStatsHeader(stats: viewModel.stats)
                .padding(.horizontal)
                .padding(.top, 16)

            // Filters Bar
            CleaningFiltersBar(
                searchText: $viewModel.searchText,
                selectedFloor: $viewModel.selectedFloor,
                selectedStatus: $viewModel.selectedStatus,
                availableFloors: viewModel.availableFloors
            )
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Room List
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading rooms...")
                Spacer()
            } else if let error = viewModel.error {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        Task {
                            await viewModel.loadRooms()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else if viewModel.filteredRooms.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("No rooms to clean")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("All rooms are ready!")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Dirty/Checked Out Rooms
                        if !viewModel.dirtyRooms.isEmpty {
                            sectionHeader(title: "Needs Cleaning", count: viewModel.dirtyRooms.count, color: .red)

                            ForEach(viewModel.dirtyRooms) { room in
                                CleaningRoomCard(
                                    room: room,
                                    onStartCleaning: {
                                        Task {
                                            await viewModel.startCleaning(roomId: room.id)
                                        }
                                    },
                                    onMarkReady: nil
                                )
                            }
                        }

                        // In Progress Rooms
                        if !viewModel.inProgressRooms.isEmpty {
                            sectionHeader(title: "In Progress", count: viewModel.inProgressRooms.count, color: .orange)

                            ForEach(viewModel.inProgressRooms) { room in
                                CleaningRoomCard(
                                    room: room,
                                    onStartCleaning: nil,
                                    onMarkReady: {
                                        Task {
                                            await viewModel.markReady(roomId: room.id)
                                        }
                                    }
                                )
                            }
                        }

                        // Ready Rooms (optional - only show if explicitly filtered)
                        if !viewModel.readyRooms.isEmpty && viewModel.selectedStatus == .ready {
                            sectionHeader(title: "Ready", count: viewModel.readyRooms.count, color: .green)

                            ForEach(viewModel.readyRooms) { room in
                                CleaningRoomCard(
                                    room: room,
                                    onStartCleaning: nil,
                                    onMarkReady: nil
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .refreshable {
                    await viewModel.loadRooms()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.loadRooms()
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

#Preview {
    HousekeepingBoardView(hotelId: UUID())
}
