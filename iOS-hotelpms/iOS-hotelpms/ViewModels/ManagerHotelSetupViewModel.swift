import Foundation
import SwiftUI

@MainActor
class ManagerHotelSetupViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var hotelName = ""
    @Published var address = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipCode = ""
    @Published var phoneNumber = ""
    @Published var isLoading = false
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // MARK: - Dependencies
    private let hotelService: HotelService
    private let membershipService: MembershipService
    private var navigationManager: NavigationManager?
    
    // MARK: - Focus State
    enum Field: Hashable {
        case hotelName, phoneNumber, address, city, state, zipCode
    }
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        return !hotelName.trimmingCharacters(in: .whitespaces).isEmpty
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
    func createHotelAndMembership() async {
        guard isFormValid else { return }
        
        isLoading = true
        
        do {
            // Create hotel and manager membership together
            let hotel = try await membershipService.createHotelWithManagerMembership(
                name: hotelName.trimmingCharacters(in: .whitespaces),
                address: address.trimmingCharacters(in: .whitespaces).isEmpty ? nil : address.trimmingCharacters(in: .whitespaces),
                city: city.trimmingCharacters(in: .whitespaces).isEmpty ? nil : city.trimmingCharacters(in: .whitespaces),
                state: state.trimmingCharacters(in: .whitespaces).isEmpty ? nil : state.trimmingCharacters(in: .whitespaces),
                zipCode: zipCode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespaces),
                hotelService: hotelService
            )
            
            // Success! Navigate to room setup
            navigationManager?.navigate(to: .roomSetup(hotelId: hotel.id))
            
        } catch {
            // Handle errors
            alertTitle = "Hotel Creation Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isLoading = false
    }
    
    // MARK: - Input Formatting Helpers
    func formatPhoneNumber(_ phoneNumber: String) -> String {
        let digits = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let length = digits.count
        
        if length == 0 {
            return ""
        } else if length <= 3 {
            return "(\(digits)"
        } else if length <= 6 {
            let areaCode = String(digits.prefix(3))
            let firstPart = String(digits.dropFirst(3))
            return "(\(areaCode)) \(firstPart)"
        } else {
            let areaCode = String(digits.prefix(3))
            let firstPart = String(digits.dropFirst(3).prefix(3))
            let lastPart = String(digits.dropFirst(6).prefix(4))
            return "(\(areaCode)) \(firstPart)-\(lastPart)"
        }
    }
    
    func formatZipCode(_ zipCode: String) -> String {
        let digits = zipCode.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return String(digits.prefix(5))
    }
}