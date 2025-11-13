import SwiftUI

struct HistoryEntryRow: View {
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color
    let isExpanded: Bool
    let room: Room?
    let changeType: String
    let onTap: () -> Void
    let onGoToRoom: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .padding(10)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())
            }
            
            if isExpanded {
                Divider()
                
                if let room = room {
                    InlineRoomSnapshot(
                        room: room,
                        changeType: changeType,
                        onGoToRoom: onGoToRoom
                    )
                } else {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading room details…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct InlineRoomSnapshot: View {
    let room: Room
    let changeType: String
    let onGoToRoom: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                StatusChip(
                    icon: "house.fill",
                    label: room.occupancyStatus.displayName,
                    tint: .blue
                )
                
                StatusChip(
                    icon: "broom",
                    label: room.cleaningStatus.displayName,
                    tint: .yellow
                )
                
                if room.flags.isEmpty {
                    StatusChip(
                        icon: "flag.slash.fill",
                        label: "No flags",
                        tint: .gray
                    )
                } else {
                    ForEach(room.flags, id: \.self) { flag in
                        StatusChip(
                            icon: flag.systemImage,
                            label: flag.displayName,
                            tint: .red
                        )
                    }
                }
            }
            
            if let notes = room.notes, !notes.isEmpty, changeType == "notes" {
                Text("“\(notes)”")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Button(action: onGoToRoom) {
                HStack(spacing: 6) {
                    Text("Go to Room")
                    Image(systemName: "arrow.forward.circle.fill")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }
}

private struct StatusChip: View {
    let icon: String
    let label: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.15))
        .foregroundColor(tint)
        .cornerRadius(10)
    }
}
