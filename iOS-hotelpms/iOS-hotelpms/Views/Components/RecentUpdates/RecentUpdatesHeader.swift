import SwiftUI

struct RecentUpdatesHeader: View {
    @ObservedObject var viewModel: RecentlyUpdatedViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Updates")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(viewModel.filteredEntries.count) recent changes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Summary chips
                HStack(spacing: 12) {
                    SummaryChip(
                        count: viewModel.todayCount,
                        label: "Today",
                        color: .blue
                    )
                    
                    SummaryChip(
                        count: viewModel.cleaningCount,
                        label: "Cleaning",
                        color: .purple
                    )
                    
                    SummaryChip(
                        count: viewModel.flagsCount,
                        label: "Flags",
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
                    
                    TextField("Search updates...", text: $viewModel.searchText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(maxWidth: 300)
                
                Spacer()
                
                // Filter Menu
                HistoryFilterMenu(selectedFilter: $viewModel.selectedFilter)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}