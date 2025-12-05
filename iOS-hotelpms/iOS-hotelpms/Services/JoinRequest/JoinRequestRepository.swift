import Foundation
import Supabase

/// Repository for join request read operations and queries
class JoinRequestRepository {

    private let supabaseClient: SupabaseClient

    init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }

    // MARK: - Join Request Queries

    /// Get all pending join requests for a hotel with profile data
    func getPendingJoinRequests(hotelId: UUID) async throws -> [JoinRequestWithProfile] {
        do {
            let response: [JoinRequestWithProfile] = try await supabaseClient
                .from("join_requests")
                .select("*, profiles(*)")
                .eq("hotel_id", value: hotelId)
                .eq("status", value: JoinRequestStatus.pending.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value

            return response
        } catch {
            throw JoinRequestServiceError.networkError("Failed to get pending join requests: \(error.localizedDescription)")
        }
    }

    /// Get a specific join request by ID
    func getJoinRequest(id: UUID) async throws -> JoinRequest {
        do {
            let response: [JoinRequest] = try await supabaseClient
                .from("join_requests")
                .select()
                .eq("id", value: id)
                .execute()
                .value

            guard let request = response.first else {
                throw JoinRequestServiceError.requestNotFound
            }

            return request
        } catch {
            if error is JoinRequestServiceError {
                throw error
            }
            throw JoinRequestServiceError.networkError("Failed to get join request: \(error.localizedDescription)")
        }
    }

    /// Check if user has a pending request for a specific hotel
    func hasPendingRequest(profileId: UUID, hotelId: UUID) async throws -> Bool {
        do {
            let response: [JoinRequest] = try await supabaseClient
                .from("join_requests")
                .select()
                .eq("profile_id", value: profileId)
                .eq("hotel_id", value: hotelId)
                .eq("status", value: JoinRequestStatus.pending.rawValue)
                .execute()
                .value

            return !response.isEmpty
        } catch {
            throw JoinRequestServiceError.networkError("Failed to check pending request: \(error.localizedDescription)")
        }
    }

    /// Get all join requests for a profile
    func getJoinRequestsForProfile(profileId: UUID) async throws -> [JoinRequest] {
        do {
            let response: [JoinRequest] = try await supabaseClient
                .from("join_requests")
                .select()
                .eq("profile_id", value: profileId)
                .order("created_at", ascending: false)
                .execute()
                .value

            return response
        } catch {
            throw JoinRequestServiceError.networkError("Failed to get join requests for profile: \(error.localizedDescription)")
        }
    }
}

// MARK: - Service Errors

enum JoinRequestServiceError: LocalizedError {
    case requestNotFound
    case duplicateRequest
    case invalidRequestData
    case networkError(String)
    case updateFailed(String)
    case userNotAuthenticated

    var errorDescription: String? {
        switch self {
        case .requestNotFound:
            return "Join request not found"
        case .duplicateRequest:
            return "You already have a pending request for this hotel"
        case .invalidRequestData:
            return "Invalid join request data provided"
        case .networkError(let message):
            return "Network error: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        }
    }
}
