import Foundation
import SwiftUI

/// Lightweight dependency registry providing access to domain services across the app.
/// Business logic orchestration now lives in ViewModels where it belongs.
class ServiceManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ServiceManager()
    
    // MARK: - Services
    @Published private(set) var roomService: RoomService
    @Published private(set) var notesService: NotesService
    @Published private(set) var roomHistoryService: RoomHistoryService
    @Published private(set) var authService: AuthService
    
    
    // MARK: - New Domain Services
    @Published private(set) var profileService: ProfileService
    @Published private(set) var hotelService: HotelService
    @Published private(set) var membershipService: MembershipService
    @Published private(set) var roomBatchService: RoomBatchService
    @Published private(set) var joinRequestService: JoinRequestService
    
    // MARK: - Legacy Service (Deprecated)
    @available(*, deprecated, message: "Use domain-specific services instead")
    @Published private(set) var databaseService: DatabaseService
    
    // MARK: - Current User Context
    @Published var currentUserId: UUID? = nil // Should be set by authentication system
    @Published var currentUserRole: HotelRole? = nil
    @Published var currentHotelId: UUID? = nil
    
    
    private init() {
        // Initialize all services
        self.roomService = RoomService()
        self.notesService = NotesService()
        self.roomHistoryService = RoomHistoryService()
        self.authService = AuthService()
        
        
        // Initialize new domain services
        self.profileService = ProfileService()
        self.hotelService = HotelService()
        self.membershipService = MembershipService()
        self.roomBatchService = RoomBatchService()
        self.joinRequestService = JoinRequestService()
        
        // Initialize deprecated service for backward compatibility
        self.databaseService = DatabaseService()
    }
    
    // MARK: - Service Access Methods
    
    /// Get the current user ID, throws error if not authenticated
    func getCurrentUserId() throws -> UUID {
        guard let userId = currentUserId else {
            throw ServiceError.userNotAuthenticated
        }
        return userId
    }
    
    /// Update current user context
    func setCurrentUser(_ userId: UUID?) {
        currentUserId = userId
    }
    
    /// Get user role for a specific hotel
    @MainActor
    func getUserRole(for hotelId: UUID) async -> HotelRole? {
        guard let userId = currentUserId else { return nil }
        
        do {
            let membership = try await membershipService.getUserMembership(userId: userId, hotelId: hotelId)
            currentUserRole = membership?.role
            currentHotelId = hotelId
            return membership?.role
        } catch {
            // Silently fail - ViewModels handle their own error states
            return nil
        }
    }
    
    /// Check if current user has admin access for current hotel
    var hasAdminAccess: Bool {
        return currentUserRole?.hasAdminAccess ?? false
    }
    
    
}

// MARK: - Service Errors

enum ServiceError: LocalizedError {
    case userNotAuthenticated
    case serviceUnavailable(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        case .serviceUnavailable(let service):
            return "Service '\(service)' is currently unavailable"
        }
    }
}

// MARK: - Environment Key for Dependency Injection

struct ServiceManagerKey: EnvironmentKey {
    static let defaultValue = ServiceManager.shared
}

extension EnvironmentValues {
    var serviceManager: ServiceManager {
        get { self[ServiceManagerKey.self] }
        set { self[ServiceManagerKey.self] = newValue }
    }
}