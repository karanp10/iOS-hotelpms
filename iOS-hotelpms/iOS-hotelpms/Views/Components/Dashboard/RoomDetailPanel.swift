import SwiftUI

struct RoomDetailPanel: View {
    let room: Room
    let onClose: () -> Void
    let onOccupancyUpdate: (OccupancyStatus) -> Void
    let onCleaningUpdate: (CleaningStatus) -> Void
    let onFlagToggle: (RoomFlag) -> Void
    let colorForOccupancy: (OccupancyStatus) -> Color
    let colorForCleaning: (CleaningStatus) -> Color
    let colorForFlag: (RoomFlag) -> Color
    
    // Notes-related properties
    @Binding var roomNotes: String
    let existingNotes: [RoomNote]
    let isLoadingNotes: Bool
    let onSaveNotes: () -> Void
    let formatDate: (Date) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with close button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Room \(room.displayNumber)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Floor \(room.floorNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Detail content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Current Status Section
                    CurrentStatusSection(
                        room: room,
                        colorForOccupancy: colorForOccupancy,
                        colorForCleaning: colorForCleaning,
                        colorForFlag: colorForFlag
                    )
                    
                    Divider()
                    
                    // Occupancy Control Section
                    OccupancyControlSection(
                        room: room,
                        colorForOccupancy: colorForOccupancy,
                        onUpdate: onOccupancyUpdate
                    )
                    
                    Divider()
                    
                    // Cleaning Control Section
                    CleaningControlSection(
                        room: room,
                        colorForCleaning: colorForCleaning,
                        onUpdate: onCleaningUpdate
                    )
                    
                    Divider()
                    
                    // Flag Toggle Section
                    FlagToggleSection(
                        room: room,
                        colorForFlag: colorForFlag,
                        onToggle: onFlagToggle
                    )
                    
                    Divider()
                    
                    // Notes Section
                    NotesPanel(
                        room: room,
                        roomNotes: $roomNotes,
                        existingNotes: existingNotes,
                        isLoadingNotes: isLoadingNotes,
                        onSaveNotes: onSaveNotes,
                        formatDate: formatDate
                    )
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct CurrentStatusSection: View {
    let room: Room
    let colorForOccupancy: (OccupancyStatus) -> Color
    let colorForCleaning: (CleaningStatus) -> Color
    let colorForFlag: (RoomFlag) -> Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                // Occupancy Status
                VStack(alignment: .leading, spacing: 4) {
                    Text("Occupancy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorForOccupancy(room.occupancyStatus))
                            .frame(width: 10, height: 10)
                        
                        Text(room.occupancyStatus.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // Cleaning Status
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cleaning")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: room.cleaningStatus.systemImage)
                            .font(.caption)
                            .foregroundColor(colorForCleaning(room.cleaningStatus))
                        
                        Text(room.cleaningStatus.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Flags section
            VStack(alignment: .leading, spacing: 4) {
                Text("Flags")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if room.hasFlags {
                    HStack(alignment: .top, spacing: 6) {
                        ForEach(room.flags, id: \.self) { flag in
                            HStack(spacing: 4) {
                                Image(systemName: flag.systemImage)
                                    .font(.system(size: 10))
                                Text(flag.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorForFlag(flag))
                            .cornerRadius(6)
                        }
                        Spacer()
                    }
                } else {
                    Text("No flags set")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
            }
        }
    }
}

struct OccupancyControlSection: View {
    let room: Room
    let colorForOccupancy: (OccupancyStatus) -> Color
    let onUpdate: (OccupancyStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Occupancy")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(OccupancyStatus.allCases, id: \.self) { status in
                    Button(action: {
                        onUpdate(status)
                    }) {
                        HStack {
                            Circle()
                                .fill(colorForOccupancy(status))
                                .frame(width: 12, height: 12)
                            
                            Text(status.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if room.occupancyStatus == status {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(room.occupancyStatus == status ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct CleaningControlSection: View {
    let room: Room
    let colorForCleaning: (CleaningStatus) -> Color
    let onUpdate: (CleaningStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Cleaning Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(CleaningStatus.allCases, id: \.self) { status in
                    Button(action: {
                        onUpdate(status)
                    }) {
                        HStack {
                            Image(systemName: status.systemImage)
                                .font(.subheadline)
                                .foregroundColor(colorForCleaning(status))
                            
                            Text(status.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if room.cleaningStatus == status {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(room.cleaningStatus == status ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct FlagToggleSection: View {
    let room: Room
    let colorForFlag: (RoomFlag) -> Color
    let onToggle: (RoomFlag) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Toggle Flags")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                FlagChip(
                    flag: .maintenanceRequired,
                    isSelected: room.flags.contains(.maintenanceRequired),
                    colorForFlag: colorForFlag,
                    onTap: { onToggle(.maintenanceRequired) }
                )
                
                FlagChip(
                    flag: .dnd,
                    isSelected: room.flags.contains(.dnd),
                    colorForFlag: colorForFlag,
                    onTap: { onToggle(.dnd) }
                )
                
                FlagChip(
                    flag: .outOfOrder,
                    isSelected: room.flags.contains(.outOfOrder),
                    colorForFlag: colorForFlag,
                    onTap: { onToggle(.outOfOrder) }
                )
                
                FlagChip(
                    flag: .outOfService,
                    isSelected: room.flags.contains(.outOfService),
                    colorForFlag: colorForFlag,
                    onTap: { onToggle(.outOfService) }
                )
            }
        }
    }
}

struct FlagChip: View {
    let flag: RoomFlag
    let isSelected: Bool
    let colorForFlag: (RoomFlag) -> Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(flagEmoji)
                    .font(.system(size: 16))
                
                Text(flag.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? colorForFlag(flag).opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? colorForFlag(flag) : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? colorForFlag(flag) : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var flagEmoji: String {
        switch flag {
        case .maintenanceRequired: return "🔧"
        case .dnd: return "🌙"
        case .outOfOrder: return "🚫"
        case .outOfService: return "🚫"
        }
    }
}

#Preview {
    let sampleRoom = Room(
        id: UUID(),
        hotelId: UUID(),
        roomNumber: 101,
        floorNumber: 1,
        occupancyStatus: .vacant,
        cleaningStatus: .ready,
        flags: [.maintenanceRequired],
        notes: "",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    RoomDetailPanel(
        room: sampleRoom,
        onClose: {},
        onOccupancyUpdate: { _ in },
        onCleaningUpdate: { _ in },
        onFlagToggle: { _ in },
        colorForOccupancy: { _ in .blue },
        colorForCleaning: { _ in .purple },
        colorForFlag: { _ in .orange },
        roomNotes: .constant("Add notes about this room..."),
        existingNotes: [],
        isLoadingNotes: false,
        onSaveNotes: {},
        formatDate: { _ in "Today 2:30 PM" }
    )
}