import Foundation
import Supabase

// MARK: - Employee Service Errors

enum EmployeeServiceError: LocalizedError {
    case networkError(String)
    case updateFailed(String)
    case employeeNotFound

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .employeeNotFound:
            return "Employee not found"
        }
    }
}

// MARK: - Employee Service

/// Facade providing employee (membership) operations for admin management
class EmployeeService {
    private let repository: EmployeeRepository
    private let mutations: EmployeeMutations

    init(
        supabaseClient: SupabaseClient? = nil,
        repository: EmployeeRepository? = nil,
        mutations: EmployeeMutations? = nil
    ) {
        let client = supabaseClient ?? SupabaseManager.shared.client
        self.repository = repository ?? EmployeeRepository(supabaseClient: client)
        self.mutations = mutations ?? EmployeeMutations(supabaseClient: client)
    }

    func getEmployees(hotelId: UUID) async throws -> [HotelEmployee] {
        try await repository.getEmployees(hotelId: hotelId)
    }

    func updateEmployeeRole(membershipId: UUID, role: HotelRole) async throws {
        try await mutations.updateEmployeeRole(membershipId: membershipId, role: role)
    }

    func removeEmployee(membershipId: UUID) async throws {
        try await mutations.removeEmployee(membershipId: membershipId)
    }
}
