import SwiftUI

struct RecentlyUpdatedView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var serviceManager = ServiceManager.shared
    
    @State private var historyEntries: [RoomHistoryEntry] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedFilter: HistoryFilter = .all
    @State private var searchText = ""
    
    enum HistoryFilter: String, CaseIterable {
        case all = "all"
        case occupancy = "occupancy_status"
        case cleaning = "cleaning_status"
        case flags = "flags"
        case notes = "notes"
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .occupancy: return "Occupancy"
            case .cleaning: return "Cleaning"
            case .flags: return "Flags"
            case .notes: return "Notes"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .occupancy: return "bed.double.fill"
            case .cleaning: return "broom.fill"
            case .flags: return "wrench.fill"
            case .notes: return "note.text"
            }
        }
    }
    
    private var filteredEntries: [RoomHistoryEntry] {
        var entries = historyEntries
        
        // Apply filter
        if selectedFilter != .all {
            entries = entries.filter { $0.changeType == selectedFilter.rawValue }
        }
        
        // Apply search
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.displayChangeDescription.localizedCaseInsensitiveContains(searchText) ||
                entry.displayUserName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return entries
    }
    
    private var groupedEntries: [String: [RoomHistoryEntry]] {
        Dictionary(grouping: filteredEntries) { entry in
            formatDateSection(entry.createdAt)
        }
    }
    
    private var sectionKeys: [String] {
        groupedEntries.keys.sorted { key1, key2 in
            // Sort by date priority: Today, Yesterday, then by date
            if key1 == "Today" { return true }
            if key2 == "Today" { return false }
            if key1 == "Yesterday" { return true }
            if key2 == "Yesterday" { return false }
            return key1 > key2
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if isLoading {
                Spacer()
                ProgressView("Loading recent updates...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
            } else if filteredEntries.isEmpty {
                emptyStateView
            } else {
                feedListView
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadHistory()
        }
        .refreshable {
            await loadHistory()
        }
        .alert("Error", isPresented: $showingError) {
            Button("Retry") {
                Task { await loadHistory() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Title and Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Updates")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(filteredEntries.count) recent changes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Summary chips
                HStack(spacing: 12) {
                    SummaryChip(
                        count: historyEntries.filter { isFromToday($0.createdAt) }.count,
                        label: "Today",
                        color: .blue
                    )
                    
                    SummaryChip(
                        count: historyEntries.filter { $0.changeType == "cleaning_status" }.count,
                        label: "Cleaning",
                        color: .purple
                    )
                    
                    SummaryChip(
                        count: historyEntries.filter { $0.changeType == "flags" }.count,
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
                    
                    TextField("Search updates...", text: $searchText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(maxWidth: 300)
                
                Spacer()
                
                // Filter Picker
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    private var feedListView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(sectionKeys, id: \.self) { sectionKey in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section Header
                        HStack {
                            Text(sectionKey)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(groupedEntries[sectionKey]?.count ?? 0) updates")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        // Entries for this section
                        LazyVStack(spacing: 8) {
                            ForEach(groupedEntries[sectionKey] ?? []) { entry in
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
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No recent updates" : "No updates match your search")
                .font(.title2)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Button("Clear Search") {
                    searchText = ""
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
        }
    }
    
    @MainActor
    private func loadHistory() async {
        isLoading = true
        
        do {
            if selectedFilter == .all {
                historyEntries = try await serviceManager.historyService.getRecentHistory(for: hotelId)
            } else {
                historyEntries = try await serviceManager.historyService.getHistoryByType(
                    for: hotelId,
                    changeType: selectedFilter.rawValue
                )
            }
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    private func formatDateSection(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func isFromToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct HistoryEntryRow: View {
    let entry: RoomHistoryEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar/Icon
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                
                if !entry.displayUserName.isEmpty && entry.displayUserName != "System" {
                    Text(userInitials)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                } else {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Main description
                Text(entry.displayChangeDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Timestamp and type
                HStack {
                    Text(formatTime(entry.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("History Entry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
            }
            
            Spacer()
            
            // Type badge
            Image(systemName: entry.changeTypeIcon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var userInitials: String {
        let components = entry.displayUserName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined()
    }
    
    private var iconColor: Color {
        switch entry.changeType {
        case "occupancy_status": return .green
        case "cleaning_status": return .blue
        case "flags": return .orange
        case "notes": return .gray
        default: return .primary
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SummaryChip: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 50)
    }
}

#Preview {
    RecentlyUpdatedView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}