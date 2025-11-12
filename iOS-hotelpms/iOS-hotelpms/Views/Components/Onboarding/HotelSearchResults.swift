import SwiftUI

struct HotelSearchResults: View {
    let hotels: [Hotel]
    let selectedHotel: Hotel?
    let onHotelSelected: (Hotel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Hotels")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(hotels) { hotel in
                HotelCard(
                    hotel: hotel, 
                    isSelected: selectedHotel?.id == hotel.id,
                    onTap: {
                        onHotelSelected(hotel)
                    }
                )
            }
        }
    }
}