import Foundation
import Supabase

// MARK: - Profile Service Errors

enum ProfileServiceError: LocalizedError {
    case profileCreationFailed(String)
    case userNotAuthenticated
    case networkError(String)
    case profileNotFound
    
    var errorDescription: String? {
        switch self {
        case .profileCreationFailed(let message):
            return "Failed to create profile: \(message)"
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        case .networkError(let message):
            return "Network error: \(message)"
        case .profileNotFound:
            return "Profile not found"
        }
    }
}

// MARK: - Profile Service

class ProfileService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    /// Creates a profile record for the authenticated user
    /// NOTE: For signup flow, profiles are now auto-created via database trigger when email is verified
    /// This method is kept for other use cases (admin operations, etc.)
    func createProfile(firstName: String, lastName: String, email: String) async throws -> Profile {
        guard let userId = supabase.auth.currentUser?.id else {
            throw ProfileServiceError.userNotAuthenticated
        }
        
        let request = CreateProfileRequest(
            firstName: firstName,
            lastName: lastName,
            email: email
        )
        
        do {
            let response: [Profile] = try await supabase
                .from("profiles")
                .insert(request)
                .select()
                .execute()
                .value
            
            guard let profile = response.first else {
                throw ProfileServiceError.profileCreationFailed("No profile returned from server")
            }
            
            return profile
        } catch {
            throw ProfileServiceError.profileCreationFailed(error.localizedDescription)
        }
    }
    
    /// Gets profile for the authenticated user
    func getCurrentProfile() async throws -> Profile {
        guard let userId = supabase.auth.currentUser?.id else {
            throw ProfileServiceError.userNotAuthenticated
        }
        
        do {
            let response: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            guard let profile = response.first else {
                throw ProfileServiceError.profileNotFound
            }
            
            return profile
        } catch {
            throw ProfileServiceError.networkError(error.localizedDescription)
        }
    }
}