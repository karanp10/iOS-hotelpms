import SwiftUI

struct CleaningStatsHeader: View {
    let stats: (dirty: Int, inProgress: Int, ready: Int)

    var body: some View {
        HStack(spacing: 12) {
            // Dirty Count
            CleaningStatCard(
                title: "Dirty",
                count: stats.dirty,
                color: .red,
                icon: "exclamationmark.triangle.fill"
            )

            // In Progress Count
            CleaningStatCard(
                title: "In Progress",
                count: stats.inProgress,
                color: .orange,
                icon: "clock.fill"
            )

            // Ready Count
            CleaningStatCard(
                title: "Ready",
                count: stats.ready,
                color: .green,
                icon: "checkmark.circle.fill"
            )
        }
    }
}

// MARK: - Cleaning Stat Card Component

private struct CleaningStatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    CleaningStatsHeader(stats: (dirty: 8, inProgress: 3, ready: 12))
        .padding()
        .background(Color(.systemGroupedBackground))
}
