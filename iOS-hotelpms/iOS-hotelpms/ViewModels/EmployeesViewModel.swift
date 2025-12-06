import Foundation
import SwiftUI

@MainActor
class EmployeesViewModel: ObservableObject {
    // MARK: - Published State
    @Published var employees: [HotelEmployee] = []
    @Published var searchText = ""
    @Published var selectedEmployee: HotelEmployee?
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var processingEmployeeIds: Set<UUID> = []

    // MARK: - Dependencies
    private let hotelId: UUID
    private let serviceManager: ServiceManager

    // MARK: - Computed Properties
    var totalCount: Int {
        employees.count
    }

    var filteredEmployees: [HotelEmployee] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return employees
        }

        return employees.filter { employee in
            employee.fullName.localizedCaseInsensitiveContains(query) ||
            employee.email.localizedCaseInsensitiveContains(query) ||
            employee.role.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    var employeesByRole: [HotelRole: [HotelEmployee]] {
        Dictionary(grouping: filteredEmployees) { $0.role }
    }

    var sortedRoles: [HotelRole] {
        let order: [HotelRole] = [.admin, .manager, .frontDesk, .housekeeping, .maintenance]
        return order.filter { employeesByRole[$0] != nil }
    }

    // MARK: - Init
    init(hotelId: UUID, serviceManager: ServiceManager = ServiceManager.shared) {
        self.hotelId = hotelId
        self.serviceManager = serviceManager
    }

    // MARK: - Load
    func loadEmployees() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            employees = try await serviceManager.employeeService.getEmployees(hotelId: hotelId)
        } catch {
            presentError("Failed to load employees: \(error.localizedDescription)")
        }
    }

    func retryLoad() {
        Task {
            await loadEmployees()
        }
    }

    // MARK: - Selection
    func selectEmployee(_ employee: HotelEmployee) {
        selectedEmployee = employee
    }

    func clearSelection() {
        selectedEmployee = nil
    }

    func isProcessing(_ id: UUID) -> Bool {
        processingEmployeeIds.contains(id)
    }

    // MARK: - Mutations
    func updateRole(for membershipId: UUID, to role: HotelRole) async {
        processingEmployeeIds.insert(membershipId)

        defer {
            processingEmployeeIds.remove(membershipId)
        }

        guard let currentEmployee = employees.first(where: { $0.id == membershipId }) else { return }

        // Optimistic update so UI reflects immediately
        let optimistic = currentEmployee.updatingRole(role)
        replaceEmployee(optimistic)
        if selectedEmployee?.id == membershipId {
            selectedEmployee = optimistic
        }

        do {
            try await serviceManager.employeeService.updateEmployeeRole(
                membershipId: membershipId,
                role: role
            )

            // Refresh from server to ensure consistency
            let refreshed = try await serviceManager.employeeService.getEmployees(hotelId: hotelId)
            employees = refreshed
            if let selectedId = selectedEmployee?.id,
               let updatedSelection = refreshed.first(where: { $0.id == selectedId }) {
                selectedEmployee = updatedSelection
            }
        } catch {
            presentError("Failed to update role: \(error.localizedDescription)")
        }
    }

    func removeEmployee(_ employee: HotelEmployee) async {
        processingEmployeeIds.insert(employee.id)

        defer {
            processingEmployeeIds.remove(employee.id)
        }

        do {
            try await serviceManager.employeeService.removeEmployee(membershipId: employee.id)
            employees.removeAll { $0.id == employee.id }

            if selectedEmployee?.id == employee.id {
                clearSelection()
            }
        } catch {
            presentError("Failed to remove employee: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers
    private func replaceEmployee(_ updated: HotelEmployee) {
        if let index = employees.firstIndex(where: { $0.id == updated.id }) {
            employees[index] = updated
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
