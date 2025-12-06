import Foundation
import Supabase

/// Read-only operations for hotel employees (approved memberships + profile data)
class EmployeeRepository {
    private let supabaseClient: SupabaseClient

    init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }

    func getEmployees(hotelId: UUID) async throws -> [HotelEmployee] {
        do {
            let response: [HotelEmployee] = try await supabaseClient
                .from("hotel_memberships")
                .select("*, profiles(*)")
                .eq("hotel_id", value: hotelId)
                .eq("status", value: MembershipStatus.approved.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value

            return response
        } catch {
            throw EmployeeServiceError.networkError("Failed to load employees: \(error.localizedDescription)")
        }
    }
}
