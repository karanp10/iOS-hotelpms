import SwiftUI

struct HistoryFilterMenu: View {
    @Binding var selectedFilter: HistoryFilter
    
    var body: some View {
        Menu {
            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                Button(action: {
                    selectedFilter = filter
                }) {
                    HStack {
                        Image(systemName: filter.icon)
                        Text(filter.displayName)
                        if selectedFilter == filter {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedFilter.icon)
                Text(selectedFilter.displayName)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .foregroundColor(.primary)
        }
    }
}