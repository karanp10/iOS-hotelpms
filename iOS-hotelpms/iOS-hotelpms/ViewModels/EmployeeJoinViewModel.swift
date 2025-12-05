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
    @Published var hasPendingRequest = false
    @Published var pendingHotelName: String?
    
    // MARK: - Dependencies
    private let serviceManager: ServiceManager
    private var navigationManager: NavigationManager?

    // MARK: - Computed Properties
    var hasSearchResults: Bool {
        !availableHotels.isEmpty
    }

    var canSearch: Bool {
        !hotelSearchText.trimmingCharacters(in: .whitespaces).isEmpty && !isSearching
    }

    var showJoinButton: Bool {
        selectedHotel != nil && !hasPendingRequest
    }

    // MARK: - Initialization
    init(serviceManager: ServiceManager = ServiceManager.shared) {
        self.serviceManager = serviceManager
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
            // Search for hotels using ServiceManager
            availableHotels = try await serviceManager.hotelService.searchHotels(query: hotelSearchText.trimmingCharacters(in: .whitespaces))

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

        // Get user ID from auth service
        guard let currentUser = serviceManager.authService.currentUser else {
            alertTitle = "Error"
            alertMessage = "You must be logged in to request to join a hotel"
            showingAlert = true
            return
        }

        let profileId = currentUser.id

        isLoading = true

        do {
            // Set the current user ID in service manager if not already set
            if serviceManager.currentUserId == nil {
                serviceManager.setCurrentUser(profileId)
            }

            // Create join request using JoinRequestService
            _ = try await serviceManager.joinRequestService.createJoinRequest(
                profileId: profileId,
                hotelId: hotel.id
            )

            // Set pending state
            hasPendingRequest = true
            pendingHotelName = hotel.name

            // Navigate to pending approval screen
            navigationManager?.navigate(to: .joinRequestPending(hotelName: hotel.name))

            // Clear selection and search after successful request
            clearSearch()

        } catch let error as JoinRequestServiceError {
            // Handle specific join request errors
            alertTitle = "Request Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
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