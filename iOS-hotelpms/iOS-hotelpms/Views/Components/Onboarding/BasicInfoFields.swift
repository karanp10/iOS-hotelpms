import SwiftUI

struct BasicInfoFields: View {
    @Binding var hotelName: String
    @Binding var phoneNumber: String
    var focusedField: FocusState<ManagerHotelSetupViewModel.Field?>.Binding
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            if horizontalSizeClass == .regular {
                // iPad: Side-by-side layout
                HStack(spacing: 12) {
                    hotelNameField
                    phoneNumberField
                }
            } else {
                // iPhone: Stacked layout
                hotelNameField
                phoneNumberField
            }
        }
    }
    
    private var hotelNameField: some View {
        TextField("Hotel Name", text: $hotelName)
            .textFieldStyle(.roundedBorder)
            .frame(height: 44)
            .focused(focusedField, equals: .hotelName)
    }
    
    private var phoneNumberField: some View {
        TextField("Phone Number", text: $phoneNumber)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad)
            .frame(height: 44)
            .focused(focusedField, equals: .phoneNumber)
    }
}