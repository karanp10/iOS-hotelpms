import SwiftUI

struct HousekeepingQueueView: View {
    @StateObject private var viewModel: HousekeepingQueueViewModel

    init(hotelId: UUID) {
        _viewModel = StateObject(wrappedValue: HousekeepingQueueViewModel(hotelId: hotelId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with counts
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cleaning Queue")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(viewModel.queueCount) waiting • \(viewModel.inProgressCount) in progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            // Content
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading queue...")
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
                            await viewModel.loadQueue()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else if viewModel.isQueueEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("No rooms in the cleaning queue")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Queued Section
                        if !viewModel.queuedRooms.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(
                                    title: "Queued",
                                    count: viewModel.queueCount,
                                    icon: "clock.fill",
                                    color: .orange
                                )

                                ForEach(viewModel.queuedRooms) { room in
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
                        }

                        // In Progress Section
                        if !viewModel.inProgressRooms.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(
                                    title: "In Progress",
                                    count: viewModel.inProgressCount,
                                    icon: "clock.arrow.circlepath",
                                    color: .blue
                                )

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
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.loadQueue()
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    HousekeepingQueueView(hotelId: UUID())
}
