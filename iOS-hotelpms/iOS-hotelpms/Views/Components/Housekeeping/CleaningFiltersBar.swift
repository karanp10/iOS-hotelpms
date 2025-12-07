import SwiftUI

struct CleaningFiltersBar: View {
    @Binding var searchText: String
    @Binding var selectedFloor: Int?
    @Binding var selectedStatus: CleaningStatus?
    let availableFloors: [Int]

    var body: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search by room number", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Clear All Button (if any filters active)
                    if selectedFloor != nil || selectedStatus != nil {
                        Button(action: clearFilters) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                Text("Clear")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(Color.red, lineWidth: 1.5)
                            )
                        }
                    }

                    // Floor Filters
                    if !availableFloors.isEmpty {
                        ForEach(availableFloors, id: \.self) { floor in
                            FilterChip(
                                title: "Floor \(floor)",
                                isSelected: selectedFloor == floor,
                                action: { toggleFloor(floor) }
                            )
                        }
                    }

                    // Status Filters
                    ForEach(CleaningStatus.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.displayName,
                            isSelected: selectedStatus == status,
                            icon: status.systemImage,
                            action: { toggleStatus(status) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Filter Actions

    private func toggleFloor(_ floor: Int) {
        if selectedFloor == floor {
            selectedFloor = nil
        } else {
            selectedFloor = floor
        }
    }

    private func toggleStatus(_ status: CleaningStatus) {
        if selectedStatus == status {
            selectedStatus = nil
        } else {
            selectedStatus = status
        }
    }

    private func clearFilters() {
        selectedFloor = nil
        selectedStatus = nil
    }
}

// MARK: - Filter Chip Component

private struct FilterChip: View {
    let title: String
    var isSelected: Bool
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.tertiarySystemGroupedBackground))
            )
        }
    }
}

#Preview {
    VStack {
        CleaningFiltersBar(
            searchText: .constant(""),
            selectedFloor: .constant(nil),
            selectedStatus: .constant(nil),
            availableFloors: [1, 2, 3, 4]
        )

        Spacer().frame(height: 30)

        CleaningFiltersBar(
            searchText: .constant("205"),
            selectedFloor: .constant(2),
            selectedStatus: .constant(.dirty),
            availableFloors: [1, 2, 3, 4]
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
