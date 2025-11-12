import Foundation
import Supabase
import PostgREST

// MARK: - Membership Service Errors

enum MembershipServiceError: LocalizedError {
    case membershipCreationFailed(String)
    case joinRequestCreationFailed(String)
    case userNotAuthenticated
    case networkError(String)
    case membershipNotFound
    
    var errorDescription: String? {
        switch self {
        case .membershipCreationFailed(let message):
            return "Failed to create membership: \(message)"
        case .joinRequestCreationFailed(let message):
            return "Failed to create join request: \(message)"
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        case .networkError(let message):
            return "Network error: \(message)"
        case .membershipNotFound:
            return "Membership not found"
        }
    }
}

// MARK: - Membership Service

class MembershipService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    /// Creates a hotel membership record
    func createHotelMembership(hotelId: UUID, role: String, status: String = "approved") async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw MembershipServiceError.userNotAuthenticated
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
            throw MembershipServiceError.membershipCreationFailed(error.localizedDescription)
        }
    }
    
    /// Gets user's hotel memberships count
    func getUserMembershipsCount() async throws -> Int {
        guard let userId = supabase.auth.currentUser?.id else {
            throw MembershipServiceError.userNotAuthenticated
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
            throw MembershipServiceError.networkError(error.localizedDescription)
        }
    }
    
    /// Gets user's membership for a specific hotel
    func getUserMembership(userId: UUID, hotelId: UUID) async throws -> HotelMembership? {
        do {
            let response: [HotelMembership] = try await supabase
                .from("hotel_memberships")
                .select()
                .eq("profile_id", value: userId)
                .eq("hotel_id", value: hotelId)
                .eq("status", value: "approved")
                .execute()
                .value
            
            return response.first
        } catch {
            throw MembershipServiceError.networkError(error.localizedDescription)
        }
    }
    
    /// Creates a join request
    func createJoinRequest(hotelId: UUID) async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw MembershipServiceError.userNotAuthenticated
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
            throw MembershipServiceError.joinRequestCreationFailed(error.localizedDescription)
        }
    }
    
    /// Creates hotel with manager membership in one transaction
    func createHotelWithManagerMembership(
        name: String,
        address: String?,
        city: String?,
        state: String?,
        zipCode: String?,
        hotelService: HotelService
    ) async throws -> Hotel {
        // Step 1: Create hotel
        let hotel = try await hotelService.createHotel(
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
}