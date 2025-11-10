import SwiftUI

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}

#Preview {
    HStack {
        StatCard(title: "Occupied", count: 5, color: .green)
        StatCard(title: "Dirty", count: 3, color: .red)
        StatCard(title: "Flagged", count: 0, color: .orange)
    }
}