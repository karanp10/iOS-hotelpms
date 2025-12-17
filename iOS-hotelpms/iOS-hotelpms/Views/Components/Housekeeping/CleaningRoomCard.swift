import SwiftUI

struct CleaningRoomCard: View {
    let room: Room
    let onStartCleaning: (() -> Void)?
    let onMarkReady: (() -> Void)?
    let onUndo: (() -> Void)?
    let isInUndoMode: Bool
    let onAddNote: (() -> Void)?
    let noteCount: Int?

    init(
        room: Room,
        onStartCleaning: (() -> Void)?,
        onMarkReady: (() -> Void)?,
        onUndo: (() -> Void)? = nil,
        isInUndoMode: Bool = false,
        onAddNote: (() -> Void)? = nil,
        noteCount: Int? = nil
    ) {
        self.room = room
        self.onStartCleaning = onStartCleaning
        self.onMarkReady = onMarkReady
        self.onUndo = onUndo
        self.isInUndoMode = isInUndoMode
        self.onAddNote = onAddNote
        self.noteCount = noteCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row
            HStack(alignment: .top) {
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

                statusChip
            }

            Spacer()

            // Action row
            HStack {
                if isInUndoMode, let undoAction = onUndo {
                    Button(action: undoAction) {
                        Label("UNDO", systemImage: "arrow.uturn.backward")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else if let startAction = onStartCleaning, room.canStartCleaning() {
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
                } else if let readyAction = onMarkReady, room.canMarkReady() {
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

                if let noteAction = onAddNote {
                    Button(action: noteAction) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "note.text")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 52, height: 36)

                            // Badge overlay - only shown when noteCount > 0
                            if let count = noteCount, count > 0 {
                                Text("\(count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(
                                        Circle()
                                            .fill(Color.red)
                                    )
                                    .offset(x: 8, y: -4)
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColorForStatus)
        )
        .frame(minHeight: 104)
    }

    // MARK: - Computed Properties

    private var backgroundColorForStatus: Color {
        switch room.cleaningStatus {
        case .dirty:
            return Color.red.opacity(0.1)
        case .cleaningInProgress:
            return Color.yellow.opacity(0.15)
        case .ready:
            return Color.green.opacity(0.1)
        }
    }

    // MARK: - Status Chip

    @ViewBuilder
    private var statusChip: some View {
        let (label, colorName): (String, String) = {
            switch room.cleaningStatus {
            case .dirty:
                return ("Dirty", "red")
            case .cleaningInProgress:
                return ("In Progress", "yellow")
            case .ready:
                return ("Ready", "green")
            }
        }()

        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(colorName).opacity(0.15)))
            .foregroundColor(Color(colorName))
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
            onMarkReady: nil,
            onAddNote: nil,
            noteCount: 0
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
            onMarkReady: {},
            onAddNote: nil,
            noteCount: 2
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
            onMarkReady: nil,
            onAddNote: nil,
            noteCount: 1
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
