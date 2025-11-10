import SwiftUI

struct RoomStatsHeader: View {
    let hotel: Hotel?
    let filteredRoomsCount: Int
    let totalRoomsCount: Int
    let rooms: [Room]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(hotel?.name ?? "Loading...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(filteredRoomsCount) of \(totalRoomsCount) rooms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick Stats
            HStack(spacing: 20) {
                StatCard(
                    title: "Occupied",
                    count: rooms.filter { $0.occupancyStatus == .occupied }.count,
                    color: .green
                )
                
                StatCard(
                    title: "Dirty",
                    count: rooms.filter { $0.cleaningStatus == .dirty }.count,
                    color: .red
                )
                
                StatCard(
                    title: "Flagged",
                    count: rooms.filter { $0.hasFlags }.count,
                    color: .orange
                )
            }
        }
    }
}

#Preview {
    RoomStatsHeader(
        hotel: nil,
        filteredRoomsCount: 45,
        totalRoomsCount: 50,
        rooms: []
    )
}