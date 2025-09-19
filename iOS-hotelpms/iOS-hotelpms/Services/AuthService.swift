import Foundation
import Supabase
import Auth

enum AuthError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case passwordsDoNotMatch
    case signupFailed(String)
    case signinFailed(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort:
            return "Password must be at least 6 characters"
        case .passwordsDoNotMatch:
            return "Passwords do not match"
        case .signupFailed(let message):
            return "Signup failed: \(message)"
        case .signinFailed(let message):
            return "Sign in failed: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

class AuthService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    @Published var isAuthenticated = false
    @Published var currentUser: Auth.User?
    
    init() {
        // Check if user is already signed in
        currentUser = supabase.auth.currentUser
        isAuthenticated = currentUser != nil
        
        // Listen for auth state changes
        Task {
            for await state in supabase.auth.authStateChanges {
                await MainActor.run {
                    currentUser = state.session?.user
                    isAuthenticated = currentUser != nil
                }
            }
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, confirmPassword: String, firstName: String? = nil, lastName: String? = nil) async throws -> Auth.User {
        // Validation
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 6 else {
            throw AuthError.passwordTooShort
        }
        
        guard password == confirmPassword else {
            throw AuthError.passwordsDoNotMatch
        }
        
        do {
            // Prepare metadata for profile creation
            var userData: [String: AnyJSON] = [:]
            if let firstName = firstName {
                userData["firstName"] = AnyJSON.string(firstName)
            }
            if let lastName = lastName {
                userData["lastName"] = AnyJSON.string(lastName)
            }
            
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: userData.isEmpty ? nil : userData
            )
            
            let user = response.user
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
            }
            
            return user
        } catch {
            throw AuthError.signupFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws -> Auth.User {
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            let user = session.user
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
            }
            
            return user
        } catch {
            throw AuthError.signinFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        try await supabase.auth.signOut()
        
        await MainActor.run {
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}