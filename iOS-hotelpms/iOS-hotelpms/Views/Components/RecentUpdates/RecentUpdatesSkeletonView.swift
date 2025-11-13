import SwiftUI

struct RecentUpdatesSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCard()
                        .shimmer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(width: 140, height: 16)
            
            VStack(alignment: .leading, spacing: 10) {
                SkeletonLine(height: 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SkeletonLine(width: 180, height: 12)
            }
            
            SkeletonLine(width: 220, height: 12)
            
            HStack(spacing: 12) {
                SkeletonLine(width: 80, height: 28)
                SkeletonLine(width: 90, height: 28)
                SkeletonLine(width: 70, height: 28)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct SkeletonLine: View {
    let width: CGFloat?
    let height: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(20))
                        .offset(x: geometry.size.width * phase)
                        .frame(width: geometry.size.width * 1.5, height: geometry.size.height * 2)
                }
                .mask(content)
            )
            .onAppear {
                guard active else { return }
                withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

private extension View {
    func shimmer(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}
