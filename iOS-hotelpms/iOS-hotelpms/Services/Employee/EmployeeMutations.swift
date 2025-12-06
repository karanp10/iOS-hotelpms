import Foundation
import Supabase

/// Write operations for employee membership records
class EmployeeMutations {
    private let supabaseClient: SupabaseClient

    init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }

    func updateEmployeeRole(membershipId: UUID, role: HotelRole) async throws {
        do {
            let request = UpdateMembershipRoleRequest(role: role.rawValue)

            let _: [String: String] = try await supabaseClient
                .from("hotel_memberships")
                .update(request)
                .eq("id", value: membershipId)
                .eq("status", value: MembershipStatus.approved.rawValue)
                .execute()
                .value
        } catch {
            throw EmployeeServiceError.updateFailed("Failed to update role: \(error.localizedDescription)")
        }
    }

    func removeEmployee(membershipId: UUID) async throws {
        do {
            let _: [String: String] = try await supabaseClient
                .from("hotel_memberships")
                .delete()
                .eq("id", value: membershipId)
                .execute()
                .value
        } catch {
            throw EmployeeServiceError.updateFailed("Failed to remove employee: \(error.localizedDescription)")
        }
    }
}
