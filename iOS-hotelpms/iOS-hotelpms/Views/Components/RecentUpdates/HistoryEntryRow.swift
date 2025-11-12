import SwiftUI

struct HistoryEntryRow: View {
    let entry: RoomHistoryEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar/Icon
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                
                if !entry.displayUserName.isEmpty && entry.displayUserName != "System" {
                    Text(userInitials)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                } else {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Main description
                Text(entry.displayChangeDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Timestamp and type
                HStack {
                    Text(formatTime(entry.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("History Entry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
            }
            
            Spacer()
            
            // Type badge
            Image(systemName: entry.changeTypeIcon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var userInitials: String {
        let components = entry.displayUserName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined()
    }
    
    private var iconColor: Color {
        switch entry.changeType {
        case "occupancy_status": return .green
        case "cleaning_status": return .blue
        case "flags": return .orange
        case "notes": return .gray
        default: return .primary
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}