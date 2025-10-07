import SwiftUI

struct RoomCard: View {
    let room: Room
    let onTap: () -> Void
    let onOccupancyTap: ((OccupancyStatus) -> Void)?
    let onCleaningTap: ((CleaningStatus) -> Void)?
    let isSelected: Bool
    
    @State private var occupancyScale: CGFloat = 1.0
    @State private var cleaningScale: CGFloat = 1.0
    
    init(
        room: Room, 
        onTap: @escaping () -> Void,
        onOccupancyTap: ((OccupancyStatus) -> Void)? = nil,
        onCleaningTap: ((CleaningStatus) -> Void)? = nil,
        isSelected: Bool = false
    ) {
        self.room = room
        self.onTap = onTap
        self.onOccupancyTap = onOccupancyTap
        self.onCleaningTap = onCleaningTap
        self.isSelected = isSelected
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
                    if room.hasFlags {
                        HStack(spacing: 2) {
                            ForEach(Array(room.flags.prefix(2)), id: \.self) { flag in
                                Text(flagEmoji(for: flag))
                                    .font(.caption)
                            }
                        }
                    }
                    
                    // Status icon based on priority
                    statusIcon
                }
                
                // Status Badges Row
                HStack(spacing: 8) {
                    // Occupancy Badge
                    occupancyBadge
                    
                    Spacer()
                    
                    // Cleaning Badge  
                    cleaningBadge
                }
                
                Spacer()
                
                // Bottom: Last Updated Time
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Updated 12m ago")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Spacer()
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
            .frame(height: 140)
            .background(backgroundForRoom)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: room.needsAttention ? 2 : 1)
            )
            .overlay(
                // Colored left border for flagged rooms
                leftBorderOverlay,
                alignment: .leading
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
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Occupancy Badge
    private var occupancyBadge: some View {
        Button(action: {
            guard let onOccupancyTap = onOccupancyTap else { return }
            
            // Animate the chip
            withAnimation(.easeInOut(duration: 0.1)) {
                occupancyScale = 0.95
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                occupancyScale = 1.0
            }
            
            // Cycle through occupancy statuses
            let nextStatus = nextOccupancyStatus(from: room.occupancyStatus)
            onOccupancyTap(nextStatus)
            
        }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(colorForOccupancy(room.occupancyStatus))
                    .frame(width: 8, height: 8)
                
                Text(room.occupancyStatus.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForOccupancy(room.occupancyStatus).opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorForOccupancy(room.occupancyStatus), lineWidth: 1)
            )
        }
        .scaleEffect(occupancyScale)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Cleaning Badge
    private var cleaningBadge: some View {
        Button(action: {
            guard let onCleaningTap = onCleaningTap else { return }
            
            // Animate the chip
            withAnimation(.easeInOut(duration: 0.1)) {
                cleaningScale = 0.95
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                cleaningScale = 1.0
            }
            
            // Cycle through cleaning statuses
            let nextStatus = nextCleaningStatus(from: room.cleaningStatus)
            onCleaningTap(nextStatus)
            
        }) {
            HStack(spacing: 4) {
                Image(systemName: room.cleaningStatus.systemImage)
                    .font(.system(size: 10))
                    .foregroundColor(colorForCleaning(room.cleaningStatus))
                
                Text(room.cleaningStatus.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForCleaning(room.cleaningStatus).opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorForCleaning(room.cleaningStatus), lineWidth: 1)
            )
        }
        .scaleEffect(cleaningScale)
        .buttonStyle(PlainButtonStyle())
    }
    
    
    
    // MARK: - Background for Room
    private var backgroundForRoom: Color {
        if room.needsAttention {
            return Color(.systemBackground).opacity(0.95)
        } else if room.occupancyStatus == .occupied || room.hasFlags {
            return Color(.secondarySystemBackground)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if room.needsAttention {
            return .orange
        } else {
            return Color(.systemGray4)
        }
    }
    
    // MARK: - Left Border for Room Status
    private var leftBorderOverlay: some View {
        Group {
            if shouldShowStatusBorder {
                Rectangle()
                    .fill(statusBorderColor)
                    .frame(width: 4)
            } else {
                EmptyView()
            }
        }
    }
    
    private var shouldShowStatusBorder: Bool {
        // Show border for: all cleaning statuses, occupied rooms, or flagged rooms
        return room.cleaningStatus == .dirty ||
               room.cleaningStatus == .cleaningInProgress ||
               room.cleaningStatus == .inspected ||
               room.occupancyStatus == .occupied ||
               room.hasFlags
    }
    
    private var statusBorderColor: Color {
        // Priority order: Cleaning status > Occupancy status > Flags
        
        // 1. Cleaning status takes highest priority
        switch room.cleaningStatus {
        case .dirty:
            return .orange
        case .cleaningInProgress:
            return .yellow
        case .inspected:
            return .purple
        }
        
        // 2. Occupancy status (only occupied gets border)
        if room.occupancyStatus == .occupied {
            return .blue
        }
        
        // 3. Flags (lowest priority)
        if room.flags.contains(.maintenanceRequired) {
            return .orange
        } else if room.flags.contains(.outOfOrder) || room.flags.contains(.outOfService) {
            return .red
        } else if room.flags.contains(.dnd) {
            return .purple
        }
        
        // Default (should not reach here if shouldShowStatusBorder logic is correct)
        return .blue
    }
    
    private var flagBorderColor: Color {
        // For backward compatibility - now delegates to statusBorderColor
        return statusBorderColor
    }
    
    // MARK: - Status Cycling Logic
    private func nextOccupancyStatus(from current: OccupancyStatus) -> OccupancyStatus {
        switch current {
        case .vacant: return .assigned
        case .assigned: return .occupied
        case .occupied: return .vacant
        case .stayover: return .vacant
        case .checkedOut: return .vacant
        }
    }
    
    private func nextCleaningStatus(from current: CleaningStatus) -> CleaningStatus {
        switch current {
        case .dirty: return .cleaningInProgress
        case .cleaningInProgress: return .inspected
        case .inspected: return .dirty
        }
    }
    
    // MARK: - Color Functions
    private func colorForOccupancy(_ status: OccupancyStatus) -> Color {
        switch status {
        case .vacant: return .green
        case .assigned: return .gray
        case .occupied: return .blue
        case .stayover: return .orange
        case .checkedOut: return .red
        }
    }
    
    private func colorForCleaning(_ status: CleaningStatus) -> Color {
        switch status {
        case .dirty: return .red
        case .cleaningInProgress: return .yellow
        case .inspected: return .purple
        }
    }
    
    private func colorForFlag(_ flag: RoomFlag) -> Color {
        switch flag {
        case .maintenanceRequired: return .orange
        case .outOfOrder: return .red
        case .outOfService: return .red
        case .dnd: return .purple
        }
    }
    
    private func flagEmoji(for flag: RoomFlag) -> String {
        switch flag {
        case .maintenanceRequired: return "🔧"
        case .outOfOrder: return "🚫"
        case .outOfService: return "🚫"
        case .dnd: return "🌙"
        }
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
                hotelId: UUID(),
                roomNumber: 205,
                floorNumber: 2,
                occupancyStatus: .occupied,
                cleaningStatus: .inspected,
                flags: [],
                notes: "Guest requested extra towels and late checkout"
            ),
            onTap: {},
            isSelected: true
        )
        
        RoomCard(
            room: Room(
                hotelId: UUID(),
                roomNumber: 310,
                floorNumber: 3,
                occupancyStatus: .vacant,
                cleaningStatus: .dirty,
                flags: [.maintenanceRequired],
                notes: "AC not working properly"
            ),
            onTap: {},
            isSelected: false
        )
        
        RoomCard(
            room: Room(
                hotelId: UUID(),
                roomNumber: 150,
                floorNumber: 1,
                occupancyStatus: .assigned,
                cleaningStatus: .cleaningInProgress,
                flags: [.dnd, .outOfOrder],
                notes: nil
            ),
            onTap: {},
            isSelected: false
        )
    }
    .padding()
}