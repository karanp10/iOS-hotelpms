import SwiftUI

struct EmployeeJoinView: View {
    @State private var hotelSearchText = ""
    @State private var selectedHotel: Hotel?
    @State private var availableHotels: [Hotel] = []
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSearching = false
    @EnvironmentObject var navigationManager: NavigationManager
    
    @StateObject private var databaseService = DatabaseService()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Join a Hotel")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Search for and request to join an existing hotel")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    // Search Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search Hotels")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("Enter hotel name...", text: $hotelSearchText)
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 44)
                                .onSubmit {
                                    Task {
                                        await searchHotels()
                                    }
                                }
                            
                            Button(action: {
                                Task {
                                    await searchHotels()
                                }
                            }) {
                                HStack {
                                    if isSearching {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            .disabled(hotelSearchText.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                        }
                    }
                    
                    // Results Section
                    if !availableHotels.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Available Hotels")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(availableHotels) { hotel in
                                HotelCard(
                                    hotel: hotel, 
                                    isSelected: selectedHotel?.id == hotel.id,
                                    onTap: {
                                        selectedHotel = hotel
                                    }
                                )
                            }
                        }
                    }
                    
                    // Join Button
                    if selectedHotel != nil {
                        Button(action: {
                            Task {
                                await requestToJoin()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                }
                                Text(isLoading ? "Sending Request..." : "Request to Join")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isLoading ? Color.gray : Color.green)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                        .padding(.top, 10)
                    }
                }
                .frame(width: min(400, geometry.size.width * 0.85))
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    @MainActor
    private func searchHotels() async {
        guard !hotelSearchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isSearching = true
        
        do {
            // Search for hotels using DatabaseService
            availableHotels = try await databaseService.searchHotels(query: hotelSearchText.trimmingCharacters(in: .whitespaces))
            
            if availableHotels.isEmpty {
                alertTitle = "No Results"
                alertMessage = "No hotels found matching '\(hotelSearchText)'. Try a different search term."
                showingAlert = true
            }
            
        } catch {
            alertTitle = "Search Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
            availableHotels = []
        }
        
        isSearching = false
    }
    
    @MainActor
    private func requestToJoin() async {
        guard let hotel = selectedHotel else { return }
        
        isLoading = true
        
        do {
            // Create join request using DatabaseService
            try await databaseService.createJoinRequest(hotelId: hotel.id)
            
            alertTitle = "Request Sent!"
            alertMessage = "Your request to join '\(hotel.name)' has been sent. You'll be notified when a manager approves your request."
            showingAlert = true
            
            // Clear selection and search after successful request
            selectedHotel = nil
            availableHotels = []
            hotelSearchText = ""
            
            // TODO: Navigate to pending approval screen or dashboard
            
        } catch {
            alertTitle = "Request Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isLoading = false
    }
}

struct HotelCard: View {
    let hotel: Hotel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(hotel.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !hotel.fullAddress.isEmpty {
                    Text(hotel.fullAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(10)
        }
    }
}

#Preview {
    EmployeeJoinView()
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}