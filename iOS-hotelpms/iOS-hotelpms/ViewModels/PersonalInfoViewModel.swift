import Foundation
import SwiftUI

@MainActor
class PersonalInfoViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    // MARK: - Dependencies
    private let authService: AuthService
    private var navigationManager: NavigationManager?
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !email.trimmingCharacters(in: .whitespaces).isEmpty &&
               password.count >= 6 &&
               password == confirmPassword
    }
    
    // MARK: - Initialization
    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }
    
    // MARK: - Setup
    func setNavigationManager(_ navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    // MARK: - Public Methods
    func createAccount() async {
        guard isFormValid else {
            validateForm()
            return
        }
        
        isLoading = true
        
        do {
            // Create account with Supabase Auth - passes firstName/lastName as metadata
            // Profile will be auto-created when user verifies email via database trigger
            let user = try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                password: password,
                confirmPassword: confirmPassword,
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces)
            )
            
            // Navigate to email verification screen
            navigationManager?.navigate(to: .emailVerification(email: email.trimmingCharacters(in: .whitespaces).lowercased()))
            
        } catch {
            // Handle signup errors
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isLoading = false
    }
    
    func validateForm() {
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Please enter your first name"
        } else if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Please enter your last name"
        } else if email.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Please enter your email address"
        } else if password.count < 6 {
            alertMessage = "Password must be at least 6 characters long"
        } else if password != confirmPassword {
            alertMessage = "Passwords do not match"
        }
        showingAlert = true
    }
}