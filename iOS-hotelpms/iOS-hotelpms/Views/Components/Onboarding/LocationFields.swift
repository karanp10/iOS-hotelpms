import SwiftUI

struct LocationFields: View {
    @Binding var address: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    var focusedField: FocusState<ManagerHotelSetupViewModel.Field?>.Binding
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Street Address", text: $address)
                .textFieldStyle(.roundedBorder)
                .frame(height: 44)
                .focused(focusedField, equals: .address)
            
            if horizontalSizeClass == .regular {
                // iPad: Two rows with city/state/zip
                HStack(spacing: 12) {
                    cityField
                    stateField
                        .frame(maxWidth: 120)
                    zipCodeField
                        .frame(maxWidth: 120)
                }
            } else {
                // iPhone: Stacked with city, then state/zip
                cityField
                
                HStack(spacing: 12) {
                    stateField
                    zipCodeField
                }
            }
        }
    }
    
    private var cityField: some View {
        TextField("City", text: $city)
            .textFieldStyle(.roundedBorder)
            .frame(height: 44)
            .focused(focusedField, equals: .city)
    }
    
    private var stateField: some View {
        TextField("State", text: $state)
            .textFieldStyle(.roundedBorder)
            .frame(height: 44)
            .focused(focusedField, equals: .state)
    }
    
    private var zipCodeField: some View {
        TextField("ZIP Code", text: $zipCode)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad)
            .frame(height: 44)
            .focused(focusedField, equals: .zipCode)
    }
}