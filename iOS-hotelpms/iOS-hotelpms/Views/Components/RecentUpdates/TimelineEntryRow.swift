import SwiftUI

struct TimelineEntryRow<Content: View>: View {
    let isFirst: Bool
    let isLast: Bool
    let indicatorColor: Color
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TimelineIndicator(
                isFirst: isFirst,
                isLast: isLast,
                color: indicatorColor
            )
            
            content()
                .padding(.bottom, isLast ? 0 : 12)
        }
    }
}

private struct TimelineIndicator: View {
    let isFirst: Bool
    let isLast: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(color.opacity(0.35))
                .frame(width: 2)
                .opacity(isFirst ? 0 : 1)
                .frame(height: 12)
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                )
                .padding(.vertical, 2)
            
            Rectangle()
                .fill(color.opacity(0.35))
                .frame(width: 2)
                .opacity(isLast ? 0 : 1)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 18)
    }
}
