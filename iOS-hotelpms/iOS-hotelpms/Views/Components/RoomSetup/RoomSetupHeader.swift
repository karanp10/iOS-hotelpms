import SwiftUI

struct RoomSetupHeader: View {
    let hotelName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "door.left.hand.open")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Room Setup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if !hotelName.isEmpty {
                    Text(hotelName)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Text("Define your room ranges")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 40)
    }
}