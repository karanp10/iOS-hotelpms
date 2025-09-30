import SwiftUI

struct RoomDashboardView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var databaseService = DatabaseService()
    
    @State private var hotel: Hotel?
    @State private var rooms: [Room] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    @State private var selectedOccupancyFilter: OccupancyStatus?
    @State private var selectedCleaningFilter: CleaningStatus?
    @State private var selectedFloorFilter: Int?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var filteredRooms: [Room] {
        rooms.filter { room in
            // Search filter
            let matchesSearch = searchText.isEmpty || 
                               String(room.roomNumber).contains(searchText)
            
            // Occupancy filter
            let matchesOccupancy = selectedOccupancyFilter == nil || 
                                  room.occupancyStatus == selectedOccupancyFilter
            
            // Cleaning filter
            let matchesCleaning = selectedCleaningFilter == nil || 
                                 room.cleaningStatus == selectedCleaningFilter
            
            // Floor filter
            let matchesFloor = selectedFloorFilter == nil || 
                              room.floorNumber == selectedFloorFilter
            
            return matchesSearch && matchesOccupancy && matchesCleaning && matchesFloor
        }
    }
    
    private var roomsByFloor: [Int: [Room]] {
        Dictionary(grouping: filteredRooms) { $0.floorNumber }
    }
    
    private var availableFloors: [Int] {
        let floors = Set(rooms.map { $0.floorNumber })
        return floors.sorted()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    // Hotel Name and Stats
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hotel?.name ?? "Loading...")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("\(filteredRooms.count) of \(rooms.count) rooms")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Quick Stats
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Occupied",
                                count: rooms.filter { $0.occupancyStatus == .occupied }.count,
                                color: .green
                            )
                            
                            StatCard(
                                title: "Dirty",
                                count: rooms.filter { $0.cleaningStatus == .dirty }.count,
                                color: .red
                            )
                            
                            StatCard(
                                title: "Flagged",
                                count: rooms.filter { $0.hasFlags }.count,
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
                                clearFilters()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                // Room Grid
                if isLoading {
                    Spacer()
                    ProgressView("Loading rooms...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Spacer()
                } else if filteredRooms.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bed.double")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text(rooms.isEmpty ? "No rooms found" : "No rooms match your filters")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        if !rooms.isEmpty && hasActiveFilters {
                            Button("Clear Filters") {
                                clearFilters()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(availableFloors.filter { roomsByFloor[$0] != nil }, id: \.self) { floor in
                                VStack(alignment: .leading, spacing: 16) {
                                    // Floor Header
                                    HStack {
                                        Text("Floor \(floor)")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("\(roomsByFloor[floor]?.count ?? 0) rooms")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Rooms Grid for this floor
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(roomsByFloor[floor] ?? []) { room in
                                            RoomCard(room: room) {
                                                // TODO: Navigate to room detail
                                                print("Tapped room \(room.roomNumber)")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadData()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var hasActiveFilters: Bool {
        !searchText.isEmpty || 
        selectedOccupancyFilter != nil || 
        selectedCleaningFilter != nil || 
        selectedFloorFilter != nil
    }
    
    private func clearFilters() {
        searchText = ""
        selectedOccupancyFilter = nil
        selectedCleaningFilter = nil
        selectedFloorFilter = nil
    }
    
    @MainActor
    private func loadData() async {
        isLoading = true
        
        do {
            // Load hotel info and rooms in parallel
            async let hotelTask = databaseService.getHotel(id: hotelId)
            async let roomsTask = databaseService.getRooms(hotelId: hotelId)
            
            hotel = try await hotelTask
            rooms = try await roomsTask
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
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
                Text(displayName(selection))
                    .foregroundColor(.secondary)
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
    RoomDashboardView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}