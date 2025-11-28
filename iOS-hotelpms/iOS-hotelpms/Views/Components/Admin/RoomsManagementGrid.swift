import SwiftUI

struct RoomsManagementGrid: View {
    let hotelId: UUID
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rooms Management")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top)
            
            Text("Rooms management interface will be implemented here")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    RoomsManagementGrid(hotelId: UUID())
}