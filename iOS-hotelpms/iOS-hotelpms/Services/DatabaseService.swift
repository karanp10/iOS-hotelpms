import Foundation
import Supabase
import PostgREST

enum DatabaseError: LocalizedError {
    case profileCreationFailed(String)
    case hotelCreationFailed(String)
    case userNotAuthenticated
    case networkError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .profileCreationFailed(let message):
            return "Failed to create profile: \(message)"
        case .hotelCreationFailed(let message):
            return "Failed to create hotel: \(message)"
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

// Request/Response models for API operations
struct CreateProfileRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }
}

struct CreateHotelRequest: Codable {
    let name: String
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let createdBy: UUID
    
    enum CodingKeys: String, CodingKey {
        case name
        case address
        case city
        case state
        case zipCode = "zip_code"
        case createdBy = "created_by"
    }
}

struct CreateMembershipRequest: Codable {
    let profileId: UUID
    let hotelId: UUID
    let role: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case hotelId = "hotel_id"
        case role
        case status
    }
}

struct CreateJoinRequest: Codable {
    let profileId: UUID
    let hotelId: UUID
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case hotelId = "hotel_id"
        case status
    }
}

class DatabaseService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Profile Operations
    
    /// Creates a profile record for the authenticated user
    /// NOTE: For signup flow, profiles are now auto-created via database trigger when email is verified
    /// This method is kept for other use cases (admin operations, etc.)
    func createProfile(firstName: String, lastName: String, email: String) async throws -> Profile {
        guard let userId = supabase.auth.currentUser?.id else {
            throw DatabaseError.userNotAuthenticated
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
                throw DatabaseError.profileCreationFailed("No profile returned from server")
            }
            
            return profile
        } catch {
            throw DatabaseError.profileCreationFailed(error.localizedDescription)
        }
    }
    
    /// Gets profile for the authenticated user
    func getCurrentProfile() async throws -> Profile {
        guard let userId = supabase.auth.currentUser?.id else {
            throw DatabaseError.userNotAuthenticated
        }
        
        do {
            let response: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            guard let profile = response.first else {
                throw DatabaseError.networkError("Profile not found")
            }
            
            return profile
        } catch {
            throw DatabaseError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Hotel Operations
    
    /// Creates a hotel record
    func createHotel(
        name: String,
        address: String?,
        city: String?,
        state: String?,
        zipCode: String?
    ) async throws -> Hotel {
        guard let userId = supabase.auth.currentUser?.id else {
            throw DatabaseError.userNotAuthenticated
        }
        
        let request = CreateHotelRequest(
            name: name,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode,
            createdBy: userId
        )
        
        do {
            let response: [Hotel] = try await supabase
                .from("hotels")
                .insert(request)
                .select()
                .execute()
                .value
            
            guard let hotel = response.first else {
                throw DatabaseError.hotelCreationFailed("No hotel returned from server")
            }
            
            return hotel
        } catch {
            throw DatabaseError.hotelCreationFailed(error.localizedDescription)
        }
    }
    
    /// Gets all hotels created by the authenticated user
    func getUserHotels() async throws -> [Hotel] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw DatabaseError.userNotAuthenticated
        }
        
        do {
            let response: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .eq("created_by", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw DatabaseError.networkError(error.localizedDescription)
        }
    }
    
    /// Gets a specific hotel by ID (with authorization check)
    func getHotel(id: UUID) async throws -> Hotel {
        guard let userId = supabase.auth.currentUser?.id else {
            throw DatabaseError.userNotAuthenticated
        }
        
        do {
            let response: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .eq("id", value: id)
                .eq("created_by", value: userId)
                .execute()
                .value
            
            guard let hotel = response.first else {
                throw DatabaseError.networkError("Hotel not found or access denied")
            }
            
            return hotel
        } catch {
            throw DatabaseError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Hotel Membership Operations
    
    /// Creates a hotel membership record
    func createHotelMembership(hotelId: UUID, role: String, status: String = "approved") async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw DatabaseError.userNotAuthenticated
        }
        
        let request = CreateMembershipRequest(
            profileId: userId,
            hotelId: hotelId,
            role: role,
            status: status
        )
        
        do {
            let _ = try await supabase
                .from("hotel_memberships")
                .insert(request)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to create membership: \(error.localizedDescription)")
        }
    }
    
    /// Gets user's hotel memberships count
    func getUserMembershipsCount() async throws -> Int {
        guard let userId = supabase.auth.currentUser?.id else {
            throw DatabaseError.userNotAuthenticated
        }
        
        do {
            let response: [[String: AnyJSON]] = try await supabase
                .from("hotel_memberships")
                .select()
                .eq("profile_id", value: userId)
                .eq("status", value: "approved")
                .execute()
                .value
            
            return response.count
        } catch {
            throw DatabaseError.networkError(error.localizedDescription)
        }
    }
    
    /// Creates hotel with manager membership in one transaction
    func createHotelWithManagerMembership(
        name: String,
        address: String?,
        city: String?,
        state: String?,
        zipCode: String?
    ) async throws -> Hotel {
        // Step 1: Create hotel
        let hotel = try await createHotel(
            name: name,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode
        )
        
        // Step 2: Create manager membership
        try await createHotelMembership(
            hotelId: hotel.id,
            role: "manager",
            status: "approved"
        )
        
        return hotel
    }
    
    // MARK: - Join Request Operations
    
    /// Creates a join request
    func createJoinRequest(hotelId: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw DatabaseError.userNotAuthenticated
        }
        
        let request = CreateJoinRequest(
            profileId: userId,
            hotelId: hotelId,
            status: "pending"
        )
        
        do {
            let _ = try await supabase
                .from("join_requests")
                .insert(request)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to create join request: \(error.localizedDescription)")
        }
    }
    
    /// Search hotels by name
    func searchHotels(query: String) async throws -> [Hotel] {
        let searchQuery = "%\(query)%"
        
        do {
            let response: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .ilike("name", pattern: searchQuery)
                .limit(10)
                .execute()
                .value
            
            return response
        } catch {
            throw DatabaseError.networkError("Failed to search hotels: \(error.localizedDescription)")
        }
    }
}
