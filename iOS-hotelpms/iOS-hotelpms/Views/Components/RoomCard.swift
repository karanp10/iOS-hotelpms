import SwiftUI

struct RoomCard: View {
    let room: Room
    let onTap: () -> Void
    let onOccupancyTap: ((OccupancyStatus) -> Void)?
    let onCleaningTap: ((CleaningStatus) -> Void)?
    let isSelected: Bool
    let isCompressed: Bool
    let recentNotes: [RoomNote]
    let nextOccupancyStatus: (OccupancyStatus) -> OccupancyStatus
    let nextCleaningStatus: (CleaningStatus) -> CleaningStatus
    
    init(
        room: Room, 
        onTap: @escaping () -> Void,
        onOccupancyTap: ((OccupancyStatus) -> Void)? = nil,
        onCleaningTap: ((CleaningStatus) -> Void)? = nil,
        isSelected: Bool = false,
        isCompressed: Bool = false,
        recentNotes: [RoomNote] = [],
        nextOccupancyStatus: @escaping (OccupancyStatus) -> OccupancyStatus = { _ in .vacant },
        nextCleaningStatus: @escaping (CleaningStatus) -> CleaningStatus = { _ in .dirty }
    ) {
        self.room = room
        self.onTap = onTap
        self.onOccupancyTap = onOccupancyTap
        self.onCleaningTap = onCleaningTap
        self.isSelected = isSelected
        self.isCompressed = isCompressed
        self.recentNotes = recentNotes
        self.nextOccupancyStatus = nextOccupancyStatus
        self.nextCleaningStatus = nextCleaningStatus
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Top Row: Room Number + Status Icon + Flag Badges
                HStack {
                    Text(room.displayNumber)
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Flag badges (show up to 2)
                    FlagBadgeRow(flags: room.flags, maxDisplayed: 2)
                    
                    // Status icon based on priority
                    statusIcon
                }
                
                // Status Badges Row
                HStack(spacing: 8) {
                    // Occupancy Badge
                    OccupancyChipView(
                        status: room.occupancyStatus,
                        isCompressed: isCompressed,
                        onTap: onOccupancyTap != nil ? {
                            let nextStatus = nextOccupancyStatus(room.occupancyStatus)
                            onOccupancyTap!(nextStatus)
                        } : nil
                    )
                    
                    Spacer()
                    
                    // Cleaning Badge  
                    CleaningChipView(
                        status: room.cleaningStatus,
                        isCompressed: isCompressed,
                        onTap: onCleaningTap != nil ? {
                            let nextStatus = nextCleaningStatus(room.cleaningStatus)
                            onCleaningTap!(nextStatus)
                        } : nil
                    )
                }
                
                Spacer()
                
                // Bottom: Last Updated Time
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Updated 12m ago")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Note icon badge for recent notes
                        if hasRecentNotes {
                            Image(systemName: "note.text")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Notes Preview below timestamp
                    if room.hasNotes {
                        Text("📝 \(room.notesPreview ?? "")")
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .frame(height: 165)
            .background(backgroundForRoom)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(
                color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.06), 
                radius: isSelected ? 8 : 2, 
                x: 0, 
                y: isSelected ? 4 : 1
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    private var hasRecentNotes: Bool {
        return recentNotes.contains { $0.roomId == room.id && $0.isRecent }
    }
    
    // MARK: - Status Icon
    private var statusIcon: some View {
        Group {
            if room.needsAttention {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            } else if room.hasFlags {
                Image(systemName: "flag.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            } else {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    
    
    
    // MARK: - Background for Room
    private var backgroundForRoom: Color {
        if room.occupancyStatus == .occupied {
            return Color(.secondarySystemBackground)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        return Color(.systemGray4)
    }
    
}

#Preview {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 16) {
        RoomCard(
            room: Room(
                id: UUID(),
                hotelId: UUID(),
                roomNumber: 205,
                floorNumber: 2,
                occupancyStatus: .occupied,
                cleaningStatus: .ready,
                flags: [],
                notes: "Guest requested extra towels and late checkout",
                createdAt: Date(),
                updatedAt: Date()
            ),
            onTap: {},
            isSelected: true
        )
        
        RoomCard(
            room: Room(
                id: UUID(),
                hotelId: UUID(),
                roomNumber: 310,
                floorNumber: 3,
                occupancyStatus: .vacant,
                cleaningStatus: .dirty,
                flags: [.maintenanceRequired],
                notes: "AC not working properly",
                createdAt: Date(),
                updatedAt: Date()
            ),
            onTap: {},
            isSelected: false
        )
        
        RoomCard(
            room: Room(
                id: UUID(),
                hotelId: UUID(),
                roomNumber: 150,
                floorNumber: 1,
                occupancyStatus: .assigned,
                cleaningStatus: .cleaningInProgress,
                flags: [.dnd, .outOfOrder],
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ),
            onTap: {},
            isSelected: false
        )
        
        // Test card with long status text to verify no truncation
        RoomCard(
            room: Room(
                id: UUID(),
                hotelId: UUID(),
                roomNumber: 250,
                floorNumber: 2,
                occupancyStatus: .stayover,
                cleaningStatus: .cleaningInProgress,
                flags: [.maintenanceRequired],
                notes: "Long notes text to test preview",
                createdAt: Date(),
                updatedAt: Date()
            ),
            onTap: {},
            isSelected: false
        )
        
        // Test card in compressed mode (icons only)
        RoomCard(
            room: Room(
                id: UUID(),
                hotelId: UUID(),
                roomNumber: 301,
                floorNumber: 3,
                occupancyStatus: .occupied,
                cleaningStatus: .dirty,
                flags: [.dnd],
                notes: "Compressed mode test",
                createdAt: Date(),
                updatedAt: Date()
            ),
            onTap: {},
            isSelected: false,
            isCompressed: true
        )
    }
    .padding()
}