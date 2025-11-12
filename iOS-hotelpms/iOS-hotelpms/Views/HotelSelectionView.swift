import SwiftUI

struct HotelSelectionView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var hotelService = HotelService()
    
    @State private var hotels: [HotelWithRoomCount] = []
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Select Hotel")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Choose which hotel to set up")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 40)
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading your hotels...")
                    Spacer()
                } else if hotels.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.crop.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No hotels found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Hotels list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(hotels, id: \.id) { hotel in
                                HotelSelectionCard(hotel: hotel) {
                                    selectHotel(hotel)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
        .task {
            await loadHotels()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @MainActor
    private func loadHotels() async {
        isLoading = true
        
        do {
            hotels = try await hotelService.getUserHotelsWithRoomCounts()
            
            // Auto-navigate if user has exactly one hotel that needs room setup
            if hotels.count == 1 && hotels[0].needsRoomSetup {
                selectHotel(hotels[0])
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
    
    private func selectHotel(_ hotel: HotelWithRoomCount) {
        if hotel.needsRoomSetup {
            // Navigate to room setup
            navigationManager.navigate(to: .roomSetup(hotelId: hotel.id))
        } else {
            // Hotel already has rooms - navigate to dashboard (placeholder for now)
            errorMessage = "Hotel '\(hotel.name)' already has \(hotel.roomCount) rooms configured."
            showingError = true
            // TODO: Navigate to dashboard when implemented
        }
    }
}

struct HotelSelectionCard: View {
    let hotel: HotelWithRoomCount
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
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
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        if hotel.needsRoomSetup {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            
                            Text("Setup Needed")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            Text("\(hotel.roomCount) Rooms")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if hotel.needsRoomSetup {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        
                        Text("This hotel needs room configuration before you can start managing rooms.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hotel.needsRoomSetup ? Color.orange.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HotelSelectionView()
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}