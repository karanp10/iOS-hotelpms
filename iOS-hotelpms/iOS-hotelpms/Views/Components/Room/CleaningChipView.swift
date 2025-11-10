import SwiftUI

struct CleaningChipView: View {
    let status: CleaningStatus
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
                Image(systemName: status.systemImage)
                    .font(.system(size: 10))
                    .foregroundColor(colorForCleaning(status))
                
                if !isCompressed {
                    Text(status.displayName)
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(colorForCleaning(status).opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorForCleaning(status), lineWidth: 1)
            )
        }
        .scaleEffect(scale)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForCleaning(_ status: CleaningStatus) -> Color {
        switch status {
        case .dirty: return .red
        case .cleaningInProgress: return .yellow
        case .ready: return .green
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        HStack(spacing: 10) {
            CleaningChipView(status: .dirty, isCompressed: false, onTap: {})
            CleaningChipView(status: .cleaningInProgress, isCompressed: false, onTap: {})
            CleaningChipView(status: .ready, isCompressed: false, onTap: {})
        }
        
        // Compressed versions
        HStack(spacing: 10) {
            CleaningChipView(status: .dirty, isCompressed: true, onTap: {})
            CleaningChipView(status: .cleaningInProgress, isCompressed: true, onTap: {})
            CleaningChipView(status: .ready, isCompressed: true, onTap: {})
        }
    }
    .padding()
}