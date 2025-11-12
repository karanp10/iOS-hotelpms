import SwiftUI

struct HistorySectionList: View {
    @ObservedObject var viewModel: RecentlyUpdatedViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.sectionKeys, id: \.self) { sectionKey in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section Header
                        HStack {
                            Text(sectionKey)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(viewModel.groupedEntries[sectionKey]?.count ?? 0) updates")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        // Entries for this section
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.groupedEntries[sectionKey] ?? []) { entry in
                                HistoryEntryRow(entry: entry)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
}