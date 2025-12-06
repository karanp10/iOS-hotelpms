import Foundation
import Supabase

/// Service for join request write operations and mutations
class JoinRequestMutations {

    private let supabaseClient: SupabaseClient
    private let repository: JoinRequestRepository

    init(supabaseClient: SupabaseClient? = nil, repository: JoinRequestRepository? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
        self.repository = repository ?? JoinRequestRepository(supabaseClient: self.supabaseClient)
    }

    // MARK: - Create Join Request

    /// Creates a join request AND a pending hotel membership
    /// This follows the plan: both join_requests and hotel_memberships rows created with status='pending'
    func createJoinRequest(profileId: UUID, hotelId: UUID) async throws -> JoinRequest {
        // Check for duplicate pending request first
        let hasPending = try await repository.hasPendingRequest(profileId: profileId, hotelId: hotelId)
        if hasPending {
            throw JoinRequestServiceError.duplicateRequest
        }

        do {
            // Step 1: Create join_requests row with status=pending
            let joinRequestData = CreateJoinRequest(
                profileId: profileId,
                hotelId: hotelId,
                status: JoinRequestStatus.pending.rawValue
            )

            let joinRequests: [JoinRequest] = try await supabaseClient
                .from("join_requests")
                .insert(joinRequestData)
                .select()
                .execute()
                .value

            guard let joinRequest = joinRequests.first else {
                throw JoinRequestServiceError.invalidRequestData
            }

            // Step 2: Create hotel_memberships row with status=pending, role=housekeeping
            let membershipData = CreateMembershipRequest(
                profileId: profileId,
                hotelId: hotelId,
                role: HotelRole.housekeeping.rawValue,
                status: MembershipStatus.pending.rawValue
            )

            let _: [HotelMembership] = try await supabaseClient
                .from("hotel_memberships")
                .insert(membershipData)
                .select()
                .execute()
                .value

            // Step 3: Notify admin via edge function
            try await notifyAdmin(joinRequestId: joinRequest.id)

            return joinRequest
        } catch {
            if error is JoinRequestServiceError {
                throw error
            }
            throw JoinRequestServiceError.networkError("Failed to create join request: \(error.localizedDescription)")
        }
    }

    // MARK: - Approve Join Request

    /// Approves a join request and assigns a role
    /// Updates join_requests.status = 'accepted' and hotel_memberships.status = 'approved' + role
    func approveJoinRequest(requestId: UUID, role: HotelRole) async throws {
        do {
            // Get the join request to find profileId and hotelId
            let joinRequest = try await repository.getJoinRequest(id: requestId)

            // Step 1: Update join_requests status to 'accepted'
            let joinRequestUpdate = UpdateJoinRequestRequest(
                status: JoinRequestStatus.accepted.rawValue
            )

            let _: [[String: AnyJSON]] = try await supabaseClient
                .from("join_requests")
                .update(joinRequestUpdate)
                .eq("id", value: requestId)
                .execute()
                .value

            // Step 2: Update hotel_memberships status to 'approved' and set role
            let membershipUpdate = UpdateMembershipStatusRequest(
                status: MembershipStatus.approved.rawValue,
                role: role.rawValue
            )

            let _: [[String: AnyJSON]] = try await supabaseClient
                .from("hotel_memberships")
                .update(membershipUpdate)
                .eq("profile_id", value: joinRequest.profileId)
                .eq("hotel_id", value: joinRequest.hotelId)
                .eq("status", value: MembershipStatus.pending.rawValue)
                .execute()
                .value

            // Note: Employee notification email is handled by approve-join-request edge function
        } catch {
            if error is JoinRequestServiceError {
                throw error
            }
            throw JoinRequestServiceError.updateFailed("Failed to approve join request: \(error.localizedDescription)")
        }
    }

    // MARK: - Reject Join Request

    /// Rejects a join request
    /// Updates both join_requests and hotel_memberships to 'rejected'
    func rejectJoinRequest(requestId: UUID) async throws {
        do {
            // Get the join request to find profileId and hotelId
            let joinRequest = try await repository.getJoinRequest(id: requestId)

            // Step 1: Update join_requests status to 'rejected'
            let joinRequestUpdate = UpdateJoinRequestRequest(
                status: JoinRequestStatus.rejected.rawValue
            )

            let _: [[String: AnyJSON]] = try await supabaseClient
                .from("join_requests")
                .update(joinRequestUpdate)
                .eq("id", value: requestId)
                .execute()
                .value

            // Step 2: Update hotel_memberships status to 'rejected'
            let membershipUpdate = UpdateMembershipStatusRequest(
                status: MembershipStatus.rejected.rawValue,
                role: nil
            )

            let _: [[String: AnyJSON]] = try await supabaseClient
                .from("hotel_memberships")
                .update(membershipUpdate)
                .eq("profile_id", value: joinRequest.profileId)
                .eq("hotel_id", value: joinRequest.hotelId)
                .eq("status", value: MembershipStatus.pending.rawValue)
                .execute()
                .value

            // Note: Employee notification email is handled by approve-join-request edge function
        } catch {
            if error is JoinRequestServiceError {
                throw error
            }
            throw JoinRequestServiceError.updateFailed("Failed to reject join request: \(error.localizedDescription)")
        }
    }

    // MARK: - Notify Admin

    /// Calls the notify-admin edge function to send email to hotel admin
    private func notifyAdmin(joinRequestId: UUID) async throws {
        do {
            // Call the edge function (fire and forget - don't block on email sending)
            struct NotifyPayload: Encodable {
                let joinRequestId: String
            }

            let payload = NotifyPayload(joinRequestId: joinRequestId.uuidString)
            let _: EmptyResponse = try await supabaseClient.functions
                .invoke(
                    "notify-admin",
                    options: FunctionInvokeOptions(
                        body: payload
                    )
                )
        } catch {
            // Log but don't fail the request if email fails
            print("Warning: Failed to notify admin: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Types

struct EmptyResponse: Codable {}
