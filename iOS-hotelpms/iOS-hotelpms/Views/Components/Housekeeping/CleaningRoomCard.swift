import SwiftUI

struct CleaningRoomCard: View {
    let room: Room
    let onStartCleaning: (() -> Void)?
    let onMarkReady: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                // Room Number
                HStack(spacing: 8) {
                    Image(systemName: "bed.double.fill")
                        .font(.title3)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Room \(room.displayNumber)")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("Floor \(room.floorNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Priority Indicator
                priorityBadge
            }

            // Status Row
            HStack(spacing: 8) {
                // Cleaning Status
                CleaningStatusChip(
                    text: room.cleaningStatus.displayName,
                    color: Color(room.cleaningStatus.color),
                    icon: room.cleaningStatus.systemImage
                )

                // Occupancy Status
                CleaningStatusChip(
                    text: room.occupancyStatus.displayName,
                    color: Color(room.occupancyStatus.color),
                    icon: nil
                )

                Spacer()
            }

            // Flags (if any)
            if room.hasFlags {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(room.flags, id: \.self) { flag in
                            CleaningFlagChip(flag: flag)
                        }
                    }
                }
            }

            // Notes Preview (if any)
            if let preview = room.notesPreview {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(preview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Action Buttons
            HStack(spacing: 8) {
                if let startAction = onStartCleaning, room.canStartCleaning() {
                    Button(action: startAction) {
                        Label("Start Cleaning", systemImage: "play.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }

                if let readyAction = onMarkReady, room.canMarkReady() {
                    Button(action: readyAction) {
                        Label("Mark Ready", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Priority Badge

    @ViewBuilder
    private var priorityBadge: some View {
        let priority = room.cleaningPriority

        if priority != .none {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(priority.color))
                    .frame(width: 8, height: 8)

                Text(priority.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(priority.color).opacity(0.15))
            )
        }
    }
}

// MARK: - Cleaning Status Chip Component

private struct CleaningStatusChip: View {
    let text: String
    let color: Color
    let icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Cleaning Flag Chip Component

private struct CleaningFlagChip: View {
    let flag: RoomFlag

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: flag.systemImage)
                .font(.caption2)
            Text(flag.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(Color(flag.color))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(flag.color).opacity(0.15))
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        // Dirty room
        CleaningRoomCard(
            room: Room(
                hotelId: UUID(),
                roomNumber: 205,
                floorNumber: 2,
                occupancyStatus: .checkedOut,
                cleaningStatus: .dirty,
                flags: [.dnd]
            ),
            onStartCleaning: {},
            onMarkReady: nil
        )

        // In progress room
        CleaningRoomCard(
            room: Room(
                hotelId: UUID(),
                roomNumber: 301,
                floorNumber: 3,
                occupancyStatus: .vacant,
                cleaningStatus: .cleaningInProgress,
                flags: []
            ),
            onStartCleaning: nil,
            onMarkReady: {}
        )

        // Ready room
        CleaningRoomCard(
            room: Room(
                hotelId: UUID(),
                roomNumber: 102,
                floorNumber: 1,
                occupancyStatus: .vacant,
                cleaningStatus: .ready,
                flags: []
            ),
            onStartCleaning: nil,
            onMarkReady: nil
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
