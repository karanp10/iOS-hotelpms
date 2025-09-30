import SwiftUI

struct ManagerHotelSetupView: View {
    @State private var hotelName = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @FocusState private var focusedField: Field?
    
    @StateObject private var databaseService = DatabaseService()
    
    enum Field: Hashable {
        case hotelName, phoneNumber, address, city, state, zipCode
    }
    
    private var isFormValid: Bool {
        return !hotelName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    
                    VStack(spacing: AdaptiveLayout.verticalSpacing(horizontalSizeClass: horizontalSizeClass)) {
                        VStack(spacing: 16) {
                            Text("Create Your Hotel")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Set up your hotel business details")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, AdaptiveLayout.topPadding(horizontalSizeClass: horizontalSizeClass))
                        
                        VStack(spacing: AdaptiveLayout.sectionSpacing(horizontalSizeClass: horizontalSizeClass)) {
                            // Hotel Basic Info
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Basic Information")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if horizontalSizeClass == .regular {
                                    // iPad: Side-by-side layout
                                    HStack(spacing: 12) {
                                        TextField("Hotel Name", text: $hotelName)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(height: 44)
                                            .focused($focusedField, equals: .hotelName)
                                        
                                        TextField("Phone Number", text: $phoneNumber)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                            .frame(height: 44)
                                            .focused($focusedField, equals: .phoneNumber)
                                    }
                                } else {
                                    // iPhone: Stacked layout
                                    TextField("Hotel Name", text: $hotelName)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(height: 44)
                                        .focused($focusedField, equals: .hotelName)
                                    
                                    TextField("Phone Number", text: $phoneNumber)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                        .frame(height: 44)
                                        .focused($focusedField, equals: .phoneNumber)
                                }
                            }
                            
                            // Location Information
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Location")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Street Address", text: $address)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(height: 44)
                                    .focused($focusedField, equals: .address)
                                
                                if horizontalSizeClass == .regular {
                                    // iPad: Two rows with city/state/zip
                                    HStack(spacing: 12) {
                                        TextField("City", text: $city)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(height: 44)
                                            .focused($focusedField, equals: .city)
                                        
                                        TextField("State", text: $state)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(height: 44)
                                            .focused($focusedField, equals: .state)
                                            .frame(maxWidth: 120)
                                        
                                        TextField("ZIP Code", text: $zipCode)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                            .frame(height: 44)
                                            .focused($focusedField, equals: .zipCode)
                                            .frame(maxWidth: 120)
                                    }
                                } else {
                                    // iPhone: Stacked with city, then state/zip
                                    TextField("City", text: $city)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(height: 44)
                                        .focused($focusedField, equals: .city)
                                    
                                    HStack(spacing: 12) {
                                        TextField("State", text: $state)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(height: 44)
                                            .focused($focusedField, equals: .state)
                                        
                                        TextField("ZIP Code", text: $zipCode)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                            .frame(height: 44)
                                            .focused($focusedField, equals: .zipCode)
                                    }
                                }
                            }
                        
                            
                            Button(action: {
                                Task {
                                    await createHotelAndMembership()
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    }
                                    Text(isLoading ? "Creating Hotel..." : "Create Hotel")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background((isFormValid && !isLoading) ? Color.blue : Color.gray)
                                .cornerRadius(10)
                            }
                            .disabled(!isFormValid || isLoading)
                            .padding(.top, 20)
                        }
                        .padding(.bottom, AdaptiveLayout.formPadding(horizontalSizeClass: horizontalSizeClass))
                    }
                    .frame(width: AdaptiveLayout.contentWidth(geometry: geometry, horizontalSizeClass: horizontalSizeClass))
                    .padding(.horizontal, AdaptiveLayout.formPadding(horizontalSizeClass: horizontalSizeClass))
                    
                    Spacer()
                }
            }
            .onTapGesture {
                focusedField = nil
            }
        }
        .navigationBarHidden(true)
        .onTapGesture {
            focusedField = nil
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    @MainActor
    private func createHotelAndMembership() async {
        isLoading = true
        
        do {
            // Create hotel and manager membership together
            let hotel = try await databaseService.createHotelWithManagerMembership(
                name: hotelName.trimmingCharacters(in: .whitespaces),
                address: address.trimmingCharacters(in: .whitespaces).isEmpty ? nil : address.trimmingCharacters(in: .whitespaces),
                city: city.trimmingCharacters(in: .whitespaces).isEmpty ? nil : city.trimmingCharacters(in: .whitespaces),
                state: state.trimmingCharacters(in: .whitespaces).isEmpty ? nil : state.trimmingCharacters(in: .whitespaces),
                zipCode: zipCode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespaces)
            )
            
            // Success! Navigate to dashboard (placeholder for now)
            alertTitle = "Success!"
            alertMessage = "Hotel '\(hotel.name)' has been created successfully! You are now the manager."
            showingAlert = true
            
            // TODO: Navigate to actual dashboard when ready
            
        } catch {
            // Handle errors
            alertTitle = "Hotel Creation Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isLoading = false
    }
}

#Preview {
    ManagerHotelSetupView()
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}