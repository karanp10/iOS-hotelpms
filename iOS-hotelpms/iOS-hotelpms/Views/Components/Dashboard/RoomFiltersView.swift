import SwiftUI

struct RoomFiltersView: View {
    @Binding var searchText: String
    @Binding var selectedOccupancyFilter: OccupancyStatus?
    @Binding var selectedCleaningFilter: CleaningStatus?
    @Binding var selectedFloorFilter: Int?
    
    let availableFloors: [Int]
    let hasActiveFilters: Bool
    let onClearFilters: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search rooms...", text: $searchText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .frame(maxWidth: 200)
            
            // Occupancy Filter
            FilterPicker(
                title: "Occupancy",
                selection: $selectedOccupancyFilter,
                options: OccupancyStatus.allCases,
                displayName: { $0?.displayName ?? "All" }
            )
            
            // Cleaning Filter
            FilterPicker(
                title: "Cleaning",
                selection: $selectedCleaningFilter,
                options: CleaningStatus.allCases,
                displayName: { $0?.displayName ?? "All" }
            )
            
            // Floor Filter
            FilterPicker(
                title: "Floor",
                selection: $selectedFloorFilter,
                options: availableFloors,
                displayName: { $0 != nil ? "Floor \($0!)" : "All" }
            )
            
            Spacer()
            
            // Clear Filters
            if hasActiveFilters {
                Button("Clear Filters") {
                    onClearFilters()
                }
                .foregroundColor(.blue)
            }
        }
    }
}

struct FilterPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T?
    let options: [T]
    let displayName: (T?) -> String
    
    var body: some View {
        Menu {
            Button(displayName(nil)) {
                selection = nil
            }
            
            Divider()
            
            ForEach(options, id: \.self) { option in
                Button(displayName(option)) {
                    selection = option
                }
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
                Text(displayName(selection))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

#Preview {
    RoomFiltersView(
        searchText: .constant(""),
        selectedOccupancyFilter: .constant(nil),
        selectedCleaningFilter: .constant(nil),
        selectedFloorFilter: .constant(nil),
        availableFloors: [1, 2, 3, 4],
        hasActiveFilters: false,
        onClearFilters: {}
    )
}