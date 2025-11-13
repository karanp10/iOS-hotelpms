import SwiftUI

struct RecentlyUpdatedView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dashboardCoordinator) private var dashboardCoordinator
    @StateObject private var viewModel: RecentlyUpdatedViewModel
    
    init(hotelId: UUID) {
        self.hotelId = hotelId
        self._viewModel = StateObject(wrappedValue: RecentlyUpdatedViewModel(hotelId: hotelId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            RecentUpdatesHeader(viewModel: viewModel)
            
            Group {
                if viewModel.isLoading {
                    RecentUpdatesSkeletonView()
                } else if viewModel.filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    HistorySectionList(
                        viewModel: viewModel,
                        onEntryTap: { entry in
                            viewModel.toggleExpanded(entry: entry)
                        },
                        onGoToRoom: { entry in
                            goToRoom(for: entry)
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Recent Updates")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadHistory()
        }
        .refreshable {
            await viewModel.loadHistory()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("Retry") {
                viewModel.retryLoad()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: viewModel.isSearchActive ? "magnifyingglass" : "sun.max")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(viewModel.isSearchActive ? "No updates match your search." : "No updates yet today. All quiet 🧼.")
                .font(.title2)
                .foregroundColor(.secondary)
            
            if viewModel.isSearchActive {
                Button("Clear Search") {
                    viewModel.clearSearch()
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
        }
    }
    
    private func goToRoom(for entry: RoomHistoryEntry) {
        if let coordinator = dashboardCoordinator {
            coordinator.selectedTab = .status
            coordinator.focusRoom(entry.roomId)
        } else {
            navigationManager.navigate(to: .roomDashboard(hotelId: hotelId, roomId: entry.roomId))
        }
    }
}


#Preview {
    RecentlyUpdatedView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}
