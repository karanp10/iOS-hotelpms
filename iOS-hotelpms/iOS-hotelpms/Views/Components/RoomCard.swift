import SwiftUI

struct RoomCard: View {
    let room: Room
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Room Number Header
                HStack {
                    Text(room.displayNumber)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if room.hasFlags {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                // Status Section
                VStack(alignment: .leading, spacing: 8) {
                    // Occupancy Status
                    HStack {
                        Circle()
                            .fill(colorForOccupancy(room.occupancyStatus))
                            .frame(width: 8, height: 8)
                        
                        Text(room.occupancyStatus.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    // Cleaning Status
                    HStack {
                        Image(systemName: room.cleaningStatus.systemImage)
                            .foregroundColor(colorForCleaning(room.cleaningStatus))
                            .font(.caption)
                        
                        Text(room.cleaningStatus.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                // Flags Section
                if room.hasFlags {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 4) {
                        ForEach(room.flags, id: \.self) { flag in
                            HStack(spacing: 4) {
                                Image(systemName: flag.systemImage)
                                    .font(.system(size: 8))
                                Text(flag.displayName)
                                    .font(.system(size: 9))
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(colorForFlag(flag))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Last Updated Footer
                HStack {
                    Text("Updated 12m ago")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("by Alice")
                        .font(.system(size: 10))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(height: 140)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: room.needsAttention ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var borderColor: Color {
        if room.needsAttention {
            return .orange
        } else {
            return Color(.systemGray4)
        }
    }
    
    private func colorForOccupancy(_ status: OccupancyStatus) -> Color {
        switch status {
        case .vacant: return .gray
        case .assigned: return .blue
        case .occupied: return .green
        case .stayover: return .orange
        case .checkedOut: return .red
        }
    }
    
    private func colorForCleaning(_ status: CleaningStatus) -> Color {
        switch status {
        case .dirty: return .red
        case .cleaningInProgress: return .yellow
        case .inspected: return .green
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
                flags: []
            ),
            onTap: {}
        )
        
        RoomCard(
            room: Room(
                hotelId: UUID(),
                roomNumber: 310,
                floorNumber: 3,
                occupancyStatus: .vacant,
                cleaningStatus: .dirty,
                flags: [.maintenanceRequired]
            ),
            onTap: {}
        )
        
        RoomCard(
            room: Room(
                hotelId: UUID(),
                roomNumber: 150,
                floorNumber: 1,
                occupancyStatus: .assigned,
                cleaningStatus: .cleaningInProgress,
                flags: [.dnd, .outOfOrder]
            ),
            onTap: {}
        )
    }
    .padding()
}