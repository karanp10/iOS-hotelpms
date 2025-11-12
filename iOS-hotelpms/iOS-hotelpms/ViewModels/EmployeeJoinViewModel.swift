import Foundation
import SwiftUI

@MainActor
class EmployeeJoinViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var hotelSearchText = ""
    @Published var selectedHotel: Hotel?
    @Published var availableHotels: [Hotel] = []
    @Published var isLoading = false
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isSearching = false
    
    // MARK: - Dependencies
    private let hotelService: HotelService
    private let membershipService: MembershipService
    private var navigationManager: NavigationManager?
    
    // MARK: - Computed Properties
    var hasSearchResults: Bool {
        !availableHotels.isEmpty
    }
    
    var canSearch: Bool {
        !hotelSearchText.trimmingCharacters(in: .whitespaces).isEmpty && !isSearching
    }
    
    var showJoinButton: Bool {
        selectedHotel != nil
    }
    
    // MARK: - Initialization
    init(hotelService: HotelService = HotelService(), membershipService: MembershipService = MembershipService()) {
        self.hotelService = hotelService
        self.membershipService = membershipService
    }
    
    // MARK: - Setup
    func setNavigationManager(_ navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    // MARK: - Public Methods
    func searchHotels() async {
        guard canSearch else { return }
        
        isSearching = true
        
        do {
            // Search for hotels using HotelService
            availableHotels = try await hotelService.searchHotels(query: hotelSearchText.trimmingCharacters(in: .whitespaces))
            
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
    
    func selectHotel(_ hotel: Hotel) {
        selectedHotel = hotel
    }
    
    func requestToJoin() async {
        guard let hotel = selectedHotel else { return }
        
        isLoading = true
        
        do {
            // Create join request using MembershipService
            try await membershipService.createJoinRequest(hotelId: hotel.id)
            
            alertTitle = "Request Sent!"
            alertMessage = "Your request to join '\(hotel.name)' has been sent. You'll be notified when a manager approves your request."
            showingAlert = true
            
            // Clear selection and search after successful request
            clearSearch()
            
            // TODO: Navigate to pending approval screen or dashboard
            
        } catch {
            alertTitle = "Request Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isLoading = false
    }
    
    func clearSearch() {
        selectedHotel = nil
        availableHotels = []
        hotelSearchText = ""
    }
}