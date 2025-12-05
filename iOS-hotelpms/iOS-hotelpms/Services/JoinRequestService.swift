import Foundation
import Supabase

/// Unified service for join request operations, combining repository and mutations
/// Follows the Repository/Mutations/Facade pattern like RoomService
class JoinRequestService {

    // MARK: - Dependencies
    private let repository: JoinRequestRepository
    private let mutations: JoinRequestMutations

    init(supabaseClient: SupabaseClient? = nil) {
        let client = supabaseClient ?? SupabaseManager.shared.client
        self.repository = JoinRequestRepository(supabaseClient: client)
        self.mutations = JoinRequestMutations(supabaseClient: client, repository: self.repository)
    }

    // MARK: - Repository Methods (Read Operations)

    /// Get all pending join requests for a hotel with profile data
    func getPendingJoinRequests(hotelId: UUID) async throws -> [JoinRequestWithProfile] {
        return try await repository.getPendingJoinRequests(hotelId: hotelId)
    }

    /// Get a specific join request by ID
    func getJoinRequest(id: UUID) async throws -> JoinRequest {
        return try await repository.getJoinRequest(id: id)
    }

    /// Check if user has a pending request for a specific hotel
    func hasPendingRequest(profileId: UUID, hotelId: UUID) async throws -> Bool {
        return try await repository.hasPendingRequest(profileId: profileId, hotelId: hotelId)
    }

    /// Get all join requests for a profile
    func getJoinRequestsForProfile(profileId: UUID) async throws -> [JoinRequest] {
        return try await repository.getJoinRequestsForProfile(profileId: profileId)
    }

    // MARK: - Mutation Methods (Write Operations)

    /// Create a join request (also creates pending hotel membership)
    func createJoinRequest(profileId: UUID, hotelId: UUID) async throws -> JoinRequest {
        return try await mutations.createJoinRequest(profileId: profileId, hotelId: hotelId)
    }

    /// Approve a join request and assign a role
    func approveJoinRequest(requestId: UUID, role: HotelRole) async throws {
        return try await mutations.approveJoinRequest(requestId: requestId, role: role)
    }

    /// Reject a join request
    func rejectJoinRequest(requestId: UUID) async throws {
        return try await mutations.rejectJoinRequest(requestId: requestId)
    }
}
