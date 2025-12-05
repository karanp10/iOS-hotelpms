import Foundation
import SwiftUI

@MainActor
class JoinRequestsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var joinRequests: [JoinRequestWithProfile] = []
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""

    // MARK: - Role Selection State
    @Published var showingRolePicker = false
    @Published var selectedRequestId: UUID?
    @Published var selectedRole: HotelRole = .housekeeping

    // MARK: - Toast State
    @Published var showingToast = false
    @Published var toastMessage = ""

    // MARK: - Processing State
    @Published var processingRequestIds: Set<UUID> = []

    // MARK: - Dependencies
    private let hotelId: UUID
    private let serviceManager: ServiceManager

    // MARK: - Computed Properties
    var pendingCount: Int {
        joinRequests.filter { $0.status == .pending }.count
    }

    func isProcessing(_ requestId: UUID) -> Bool {
        processingRequestIds.contains(requestId)
    }

    // MARK: - Initialization
    init(
        hotelId: UUID,
        serviceManager: ServiceManager = ServiceManager.shared
    ) {
        self.hotelId = hotelId
        self.serviceManager = serviceManager
    }

    // MARK: - Data Loading
    func loadJoinRequests() async {
        isLoading = true

        defer {
            isLoading = false
        }

        do {
            joinRequests = try await serviceManager.joinRequestService.getPendingJoinRequests(hotelId: hotelId)
        } catch {
            errorMessage = "Failed to load join requests: \(error.localizedDescription)"
            showingError = true
        }
    }

    // MARK: - Approval Flow

    /// Start the approval process - shows role picker
    func startApproval(requestId: UUID) {
        selectedRequestId = requestId
        selectedRole = .housekeeping  // Default selection
        showingRolePicker = true
    }

    /// Confirm approval with selected role
    func confirmApproval() async {
        guard let requestId = selectedRequestId else { return }

        // Close role picker
        showingRolePicker = false

        // Mark as processing
        processingRequestIds.insert(requestId)

        defer {
            processingRequestIds.remove(requestId)
        }

        do {
            // Get requester name for toast message
            let requesterName = joinRequests.first(where: { $0.id == requestId })?.fullName ?? "Employee"

            // Approve the request
            try await serviceManager.joinRequestService.approveJoinRequest(
                requestId: requestId,
                role: selectedRole
            )

            // Remove from list (optimistic update)
            joinRequests.removeAll { $0.id == requestId }

            // Show success toast
            toastMessage = "\(requesterName) approved as \(selectedRole.displayName) ✅"
            showToast()

            // Reload to get fresh data
            await loadJoinRequests()
        } catch {
            errorMessage = "Failed to approve request: \(error.localizedDescription)"
            showingError = true
        }

        // Reset selection
        selectedRequestId = nil
    }

    /// Cancel approval (close role picker)
    func cancelApproval() {
        showingRolePicker = false
        selectedRequestId = nil
    }

    // MARK: - Rejection Flow

    func rejectRequest(requestId: UUID) async {
        // Mark as processing
        processingRequestIds.insert(requestId)

        defer {
            processingRequestIds.remove(requestId)
        }

        do {
            // Get requester name for toast message
            let requesterName = joinRequests.first(where: { $0.id == requestId })?.fullName ?? "Employee"

            // Reject the request
            try await serviceManager.joinRequestService.rejectJoinRequest(requestId: requestId)

            // Remove from list (optimistic update)
            joinRequests.removeAll { $0.id == requestId }

            // Show success toast
            toastMessage = "\(requesterName)'s request was rejected"
            showToast()

            // Reload to get fresh data
            await loadJoinRequests()
        } catch {
            errorMessage = "Failed to reject request: \(error.localizedDescription)"
            showingError = true
        }
    }

    // MARK: - Toast Management

    private func showToast() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showingToast = false
            }
        }
    }

    // MARK: - Error Handling

    func retryLoad() {
        Task {
            await loadJoinRequests()
        }
    }
}
