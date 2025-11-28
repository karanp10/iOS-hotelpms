import SwiftUI

struct HotelSettingsForm: View {
    let hotelId: UUID
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Hotel Settings")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top)
            
            Text("Hotel settings form will be implemented here")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    HotelSettingsForm(hotelId: UUID())
}