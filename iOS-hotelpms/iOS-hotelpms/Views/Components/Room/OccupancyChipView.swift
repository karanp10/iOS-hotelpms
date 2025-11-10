import SwiftUI

struct OccupancyChipView: View {
    let status: OccupancyStatus
    let isCompressed: Bool
    let onTap: (() -> Void)?
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            guard let onTap = onTap else { return }
            
            // Animate the chip
            withAnimation(.easeInOut(duration: 0.1)) {
                scale = 0.95
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            onTap()
        }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(colorForOccupancy(status))
                    .frame(width: 8, height: 8)
                
                if !isCompressed {
                    Text(status.displayName)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(colorForOccupancy(status).opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorForOccupancy(status), lineWidth: 1)
            )
        }
        .scaleEffect(scale)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForOccupancy(_ status: OccupancyStatus) -> Color {
        switch status {
        case .vacant: return .green
        case .assigned: return .gray
        case .occupied: return .blue
        case .stayover: return .orange
        case .checkedOut: return .red
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        HStack(spacing: 10) {
            OccupancyChipView(status: .vacant, isCompressed: false, onTap: {})
            OccupancyChipView(status: .assigned, isCompressed: false, onTap: {})
            OccupancyChipView(status: .occupied, isCompressed: false, onTap: {})
        }
        
        HStack(spacing: 10) {
            OccupancyChipView(status: .stayover, isCompressed: false, onTap: {})
            OccupancyChipView(status: .checkedOut, isCompressed: false, onTap: {})
        }
        
        // Compressed versions
        HStack(spacing: 10) {
            OccupancyChipView(status: .vacant, isCompressed: true, onTap: {})
            OccupancyChipView(status: .occupied, isCompressed: true, onTap: {})
            OccupancyChipView(status: .assigned, isCompressed: true, onTap: {})
        }
    }
    .padding()
}