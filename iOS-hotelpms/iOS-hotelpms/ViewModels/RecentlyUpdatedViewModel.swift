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
    @Published var sortOrder: HistorySortOrder = .newestFirst
    @Published var expandedEntryId: UUID?
    
    // MARK: - Dependencies
    private let hotelId: UUID
    private let serviceManager: ServiceManager
    private var roomCache: [UUID: Room] = [:]
    
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
        
        entries.sort { lhs, rhs in
            switch sortOrder {
            case .newestFirst:
                return lhs.createdAt > rhs.createdAt
            case .oldestFirst:
                return lhs.createdAt < rhs.createdAt
            }
        }
        
        return entries
    }
    
    var sections: [HistorySectionDisplay] {
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            formatDateSection(entry.createdAt)
        }
        
        return grouped.map { key, value in
            let sortDate = value.first?.createdAt ?? Date.distantPast
            return HistorySectionDisplay(title: key, entries: value, sortDate: sortDate)
        }
        .sorted { lhs, rhs in
            if lhs.title == "Today" { return true }
            if rhs.title == "Today" { return false }
            if lhs.title == "Yesterday" && rhs.title != "Today" { return true }
            if rhs.title == "Yesterday" && lhs.title != "Today" { return false }
            
            switch sortOrder {
            case .newestFirst:
                return lhs.sortDate > rhs.sortDate
            case .oldestFirst:
                return lhs.sortDate < rhs.sortDate
            }
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
    
    var isSearchActive: Bool {
        !searchText.isEmpty
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
            async let historyTask = serviceManager.roomHistoryService.getRecentHistoryForHotel(hotelId: hotelId)
            async let roomsTask = serviceManager.roomService.getRooms(hotelId: hotelId)
            
            let (history, rooms) = try await (historyTask, roomsTask)
            historyEntries = history
            roomCache = Dictionary(uniqueKeysWithValues: rooms.map { ($0.id, $0) })
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
    
    func toggleSortOrder() {
        sortOrder = sortOrder == .newestFirst ? .oldestFirst : .newestFirst
    }
    
    func toggleExpanded(entry: RoomHistoryEntry) {
        if expandedEntryId == entry.id {
            expandedEntryId = nil
            return
        }
        
        expandedEntryId = entry.id
        Task { await preloadRoom(entry.roomId) }
    }
    
    func isExpanded(_ entry: RoomHistoryEntry) -> Bool {
        expandedEntryId == entry.id
    }
    
    func room(for entry: RoomHistoryEntry) -> Room? {
        roomCache[entry.roomId]
    }
    
    func primaryDescription(for entry: RoomHistoryEntry) -> String {
        let roomName = roomDisplayName(for: entry)
        
        switch entry.changeType {
        case "occupancy_status":
            if let oldValue = entry.oldValue, let newValue = entry.newValue {
                let from = formatOccupancy(oldValue)
                let to = formatOccupancy(newValue)
                return "\(roomName) — \(from) → \(to)"
            }
            return "\(roomName) — Occupancy updated"
        case "cleaning_status":
            if let oldValue = entry.oldValue, let newValue = entry.newValue {
                let from = formatCleaning(oldValue)
                let to = formatCleaning(newValue)
                return "\(roomName) — \(from) → \(to)"
            }
            return "\(roomName) — Cleaning updated"
        case "flags":
            if let note = entry.note, !note.isEmpty {
                return "\(roomName) — \(note)"
            }
            return "\(roomName) — Flags updated"
        case "notes":
            return "\(roomName) — Added note"
        default:
            return "\(roomName) — Updated"
        }
    }
    
    func secondaryDescription(for entry: RoomHistoryEntry) -> String {
        "\(entry.displayUserName) • \(formatTime(entry.createdAt))"
    }
    
    func iconName(for entry: RoomHistoryEntry) -> String {
        switch entry.changeType {
        case "occupancy_status": return "house.fill"
        case "cleaning_status": return "broom"
        case "flags": return "flag.fill"
        case "notes": return "note.text"
        default: return "circle.fill"
        }
    }
    
    func iconColor(for entry: RoomHistoryEntry) -> Color {
        switch entry.changeType {
        case "occupancy_status": return Color.blue
        case "cleaning_status": return Color.yellow
        case "flags": return Color.red
        case "notes": return Color.gray
        default: return Color.accentColor
        }
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func roomDisplayName(for entry: RoomHistoryEntry) -> String {
        if let room = roomCache[entry.roomId] {
            return "Room \(room.displayNumber)"
        }
        return "Room"
    }
    
    private func formatOccupancy(_ value: String) -> String {
        OccupancyStatus(rawValue: value)?.displayName ?? value.capitalized
    }
    
    private func formatCleaning(_ value: String) -> String {
        CleaningStatus(rawValue: value)?.displayName ?? value.capitalized
    }
    
    private func preloadRoom(_ roomId: UUID) async {
        guard roomCache[roomId] == nil else { return }
        
        do {
            let room = try await serviceManager.roomService.getRoom(id: roomId)
            roomCache[roomId] = room
        } catch {
            // Ignore individual room load failures; inline preview will show placeholder
            print("Failed to load room \(roomId): \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

struct HistorySectionDisplay: Identifiable {
    var id: String { title }
    let title: String
    let entries: [RoomHistoryEntry]
    let sortDate: Date
    
    var isToday: Bool {
        title == "Today"
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

enum HistorySortOrder {
    case newestFirst
    case oldestFirst
}
