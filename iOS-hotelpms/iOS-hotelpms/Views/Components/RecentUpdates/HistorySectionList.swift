import SwiftUI

struct HistorySectionList: View {
    @ObservedObject var viewModel: RecentlyUpdatedViewModel
    let onEntryTap: (RoomHistoryEntry) -> Void
    let onGoToRoom: (RoomHistoryEntry) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.sections) { section in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(section.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if section.isToday {
                                Text("Live")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.15))
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            Text("\(section.entries.count) updates")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                                TimelineEntryRow(
                                    isFirst: index == 0,
                                    isLast: index == section.entries.count - 1,
                                    indicatorColor: viewModel.iconColor(for: entry)
                                ) {
                                    HistoryEntryRow(
                                        title: viewModel.primaryDescription(for: entry),
                                        subtitle: viewModel.secondaryDescription(for: entry),
                                        iconName: viewModel.iconName(for: entry),
                                        iconColor: viewModel.iconColor(for: entry),
                                        isExpanded: viewModel.isExpanded(entry),
                                        room: viewModel.room(for: entry),
                                        changeType: entry.changeType,
                                        onTap: { onEntryTap(entry) },
                                        onGoToRoom: { onGoToRoom(entry) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                    .background(section.isToday ? Color.blue.opacity(0.05) : Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: section.isToday ? Color.blue.opacity(0.12) : Color.black.opacity(0.05), radius: section.isToday ? 10 : 4, x: 0, y: section.isToday ? 6 : 2)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
    }
}
