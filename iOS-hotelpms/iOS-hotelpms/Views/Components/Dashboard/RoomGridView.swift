import SwiftUI

struct RoomGridView: View {
    let roomsByFloor: [Int: [Room]]
    let availableFloors: [Int]
    let selectedRoomId: UUID?
    let selectedRoom: Room?
    let recentNotes: [RoomNote]
    let scrollTargetId: UUID?
    let onScrollConsumed: () -> Void
    
    let onRoomTap: (Room) -> Void
    let onOccupancyTap: (Room, OccupancyStatus) -> Void
    let onCleaningTap: (Room, CleaningStatus) -> Void
    let nextOccupancyStatus: (OccupancyStatus) -> OccupancyStatus
    let nextCleaningStatus: (CleaningStatus) -> CleaningStatus
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(availableFloors.filter { roomsByFloor[$0] != nil }, id: \.self) { floor in
                        VStack(alignment: .leading, spacing: 16) {
                            // Floor Header
                            HStack {
                                Text("Floor \(floor)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(roomsByFloor[floor]?.count ?? 0) rooms")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Rooms Grid for this floor
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(roomsByFloor[floor] ?? []) { room in
                                    RoomCard(
                                        room: room,
                                        onTap: {
                                            onRoomTap(room)
                                        },
                                        onOccupancyTap: { newStatus in
                                            onOccupancyTap(room, newStatus)
                                        },
                                        onCleaningTap: { newStatus in
                                            onCleaningTap(room, newStatus)
                                        },
                                        isSelected: selectedRoomId == room.id,
                                        isCompressed: selectedRoom != nil,
                                        recentNotes: recentNotes,
                                        nextOccupancyStatus: nextOccupancyStatus,
                                        nextCleaningStatus: nextCleaningStatus
                                    )
                                    .id(room.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: scrollTargetId) { id in
                guard let id else { return }
                scrollToRoom(id, proxy: proxy)
            }
            .onAppear {
                if let id = scrollTargetId {
                    scrollToRoom(id, proxy: proxy, animated: false)
                }
            }
        }
    }
    
    private func scrollToRoom(_ id: UUID, proxy: ScrollViewProxy, animated: Bool = true) {
        let action = {
            proxy.scrollTo(id, anchor: .center)
            onScrollConsumed()
        }
        
        if animated {
            withAnimation(.easeInOut(duration: 0.4)) {
                action()
            }
        } else {
            action()
        }
    }
}

#Preview {
    let sampleRooms = [
        Room(id: UUID(), hotelId: UUID(), roomNumber: 101, floorNumber: 1, occupancyStatus: .vacant, cleaningStatus: .ready, flags: [], notes: "", createdAt: Date(), updatedAt: Date()),
        Room(id: UUID(), hotelId: UUID(), roomNumber: 102, floorNumber: 1, occupancyStatus: .occupied, cleaningStatus: .dirty, flags: [], notes: "", createdAt: Date(), updatedAt: Date())
    ]
    
    RoomGridView(
        roomsByFloor: [1: sampleRooms],
        availableFloors: [1],
        selectedRoomId: nil,
        selectedRoom: nil,
        recentNotes: [],
        scrollTargetId: nil,
        onScrollConsumed: {},
        onRoomTap: { _ in },
        onOccupancyTap: { _, _ in },
        onCleaningTap: { _, _ in },
        nextOccupancyStatus: { _ in .vacant },
        nextCleaningStatus: { _ in .dirty }
    )
}
