import SwiftUI

struct RecentlyUpdatedView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var viewModel: RecentlyUpdatedViewModel
    
    init(hotelId: UUID) {
        self.hotelId = hotelId
        self._viewModel = StateObject(wrappedValue: RecentlyUpdatedViewModel(hotelId: hotelId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            RecentUpdatesHeader(viewModel: viewModel)
            
            // Content
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading recent updates...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
            } else if viewModel.filteredEntries.isEmpty {
                emptyStateView
            } else {
                HistorySectionList(viewModel: viewModel)
            }
        }
        .navigationBarHidden(true)
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
            
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(viewModel.searchText.isEmpty ? "No recent updates" : "No updates match your search")
                .font(.title2)
                .foregroundColor(.secondary)
            
            if !viewModel.searchText.isEmpty {
                Button("Clear Search") {
                    viewModel.clearSearch()
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
        }
    }
}


#Preview {
    RecentlyUpdatedView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}