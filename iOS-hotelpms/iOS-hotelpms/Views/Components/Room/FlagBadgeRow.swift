import SwiftUI

struct FlagBadgeRow: View {
    let flags: [RoomFlag]
    let maxDisplayed: Int
    
    init(flags: [RoomFlag], maxDisplayed: Int = 2) {
        self.flags = flags
        self.maxDisplayed = maxDisplayed
    }
    
    var body: some View {
        if !flags.isEmpty {
            HStack(spacing: 2) {
                ForEach(Array(flags.prefix(maxDisplayed)), id: \.self) { flag in
                    Text(flagEmoji(for: flag))
                        .font(.caption)
                }
                
                // Show "+" indicator if there are more flags
                if flags.count > maxDisplayed {
                    Text("+\(flags.count - maxDisplayed)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
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
    VStack(spacing: 10) {
        HStack {
            Text("No flags:")
            FlagBadgeRow(flags: [])
        }
        
        HStack {
            Text("One flag:")
            FlagBadgeRow(flags: [.maintenanceRequired])
        }
        
        HStack {
            Text("Two flags:")
            FlagBadgeRow(flags: [.maintenanceRequired, .dnd])
        }
        
        HStack {
            Text("Many flags:")
            FlagBadgeRow(flags: [.maintenanceRequired, .dnd, .outOfOrder, .outOfService])
        }
        
        HStack {
            Text("Max 3:")
            FlagBadgeRow(flags: [.maintenanceRequired, .dnd, .outOfOrder, .outOfService], maxDisplayed: 3)
        }
    }
    .padding()
}