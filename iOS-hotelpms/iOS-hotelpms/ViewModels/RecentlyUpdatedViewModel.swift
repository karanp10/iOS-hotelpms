import Foundation
import SwiftUI

@MainActor
class RecentlyUpdatedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var historyEntries: [RoomHistoryEntry] = []
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    // MARK: - Filter Properties
    @Published var selectedFilter: HistoryFilter = .all
    @Published var searchText = ""
    
    // MARK: - Dependencies
    private let hotelId: UUID
    private let serviceManager: ServiceManager
    
    // MARK: - Computed Properties
    var filteredEntries: [RoomHistoryEntry] {
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
    
    var groupedEntries: [String: [RoomHistoryEntry]] {
        Dictionary(grouping: filteredEntries) { entry in
            formatDateSection(entry.createdAt)
        }
    }
    
    var sectionKeys: [String] {
        groupedEntries.keys.sorted { key1, key2 in
            // Sort by date priority: Today, Yesterday, then by date
            if key1 == "Today" { return true }
            if key2 == "Today" { return false }
            if key1 == "Yesterday" { return true }
            if key2 == "Yesterday" { return false }
            return key1 > key2
        }
    }
    
    var todayCount: Int {
        historyEntries.filter { isFromToday($0.createdAt) }.count
    }
    
    var cleaningCount: Int {
        historyEntries.filter { $0.changeType == "cleaning_status" }.count
    }
    
    var flagsCount: Int {
        historyEntries.filter { $0.changeType == "flags" }.count
    }
    
    // MARK: - Initialization
    init(hotelId: UUID, serviceManager: ServiceManager = ServiceManager.shared) {
        self.hotelId = hotelId
        self.serviceManager = serviceManager
    }
    
    // MARK: - Public Methods
    func loadHistory() async {
        isLoading = true
        
        do {
            if selectedFilter == .all {
                historyEntries = try await serviceManager.roomHistoryService.getRecentHistoryForHotel(hotelId: hotelId)
            } else {
                historyEntries = try await serviceManager.roomHistoryService.getActivityByChangeType(
                    changeType: selectedFilter.rawValue
                )
            }
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    func retryLoad() {
        Task { await loadHistory() }
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Private Helpers
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

// MARK: - HistoryFilter Enum
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