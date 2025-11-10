import Foundation
import SwiftUI

/// Centralized service manager for consistent dependency injection across the app
class ServiceManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ServiceManager()
    
    // MARK: - Services
    @Published private(set) var roomService: RoomService
    @Published private(set) var notesService: NotesService
    @Published private(set) var auditService: AuditService
    @Published private(set) var databaseService: DatabaseService
    @Published private(set) var authService: AuthService
    @Published private(set) var historyService: HistoryService
    
    // MARK: - Current User Context
    @Published var currentUserId: UUID? = nil // Should be set by authentication system
    @Published var currentUserRole: HotelRole? = nil
    @Published var currentHotelId: UUID? = nil
    
    // MARK: - Global Loading States
    @Published var isLoadingRooms = false
    @Published var isLoadingNotes = false
    @Published var isCreatingAuditRecord = false
    
    // MARK: - Error Handling
    @Published var lastError: Error?
    @Published var showingError = false
    
    private init() {
        // Initialize all services
        self.roomService = RoomService()
        self.notesService = NotesService()
        self.auditService = AuditService()
        self.databaseService = DatabaseService()
        self.authService = AuthService()
        self.historyService = HistoryService()
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
            let membership = try await databaseService.getUserMembership(userId: userId, hotelId: hotelId)
            currentUserRole = membership?.role
            currentHotelId = hotelId
            return membership?.role
        } catch {
            handleError(error)
            return nil
        }
    }
    
    /// Check if current user has admin access for current hotel
    var hasAdminAccess: Bool {
        return currentUserRole?.hasAdminAccess ?? false
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        lastError = error
        showingError = true
    }
    
    func clearError() {
        lastError = nil
        showingError = false
    }
    
    // MARK: - Convenient Service Methods with Error Handling
    
    @MainActor
    func loadRooms(for hotelId: UUID) async -> [Room] {
        isLoadingRooms = true
        defer { isLoadingRooms = false }
        
        do {
            return try await roomService.getRooms(hotelId: hotelId)
        } catch {
            handleError(error)
            return []
        }
    }
    
    @MainActor
    func loadNotes(for roomId: UUID) async -> [RoomNote] {
        isLoadingNotes = true
        defer { isLoadingNotes = false }
        
        do {
            return try await notesService.getNotesForRoom(roomId: roomId)
        } catch {
            handleError(error)
            return []
        }
    }
    
    func updateRoomOccupancy(roomId: UUID, newStatus: OccupancyStatus, previousStatus: OccupancyStatus) async -> Bool {
        do {
            let userId = try getCurrentUserId()
            
            try await roomService.updateOccupancyStatus(
                roomId: roomId,
                newStatus: newStatus,
                updatedBy: userId
            )
            
            // Create audit trail
            isCreatingAuditRecord = true
            defer { isCreatingAuditRecord = false }
            
            try await auditService.logOccupancyChange(
                roomId: roomId,
                actorId: userId,
                from: previousStatus,
                to: newStatus
            )
            
            return true
        } catch {
            handleError(error)
            return false
        }
    }
    
    func updateRoomCleaning(roomId: UUID, newStatus: CleaningStatus, previousStatus: CleaningStatus) async -> Bool {
        do {
            let userId = try getCurrentUserId()
            
            try await roomService.updateCleaningStatus(
                roomId: roomId,
                newStatus: newStatus,
                updatedBy: userId
            )
            
            // Create audit trail
            isCreatingAuditRecord = true
            defer { isCreatingAuditRecord = false }
            
            try await auditService.logCleaningChange(
                roomId: roomId,
                actorId: userId,
                from: previousStatus,
                to: newStatus
            )
            
            return true
        } catch {
            handleError(error)
            return false
        }
    }
    
    func toggleRoomFlag(roomId: UUID, flag: RoomFlag, isRemoving: Bool) async -> Bool {
        do {
            let userId = try getCurrentUserId()
            
            try await roomService.toggleFlag(
                roomId: roomId,
                flag: flag,
                updatedBy: userId
            )
            
            // Create audit trail
            isCreatingAuditRecord = true
            defer { isCreatingAuditRecord = false }
            
            if isRemoving {
                try await auditService.logFlagRemoved(
                    roomId: roomId,
                    actorId: userId,
                    flag: flag
                )
            } else {
                try await auditService.logFlagAdded(
                    roomId: roomId,
                    actorId: userId,
                    flag: flag
                )
            }
            
            return true
        } catch {
            handleError(error)
            return false
        }
    }
    
    func saveNote(roomId: UUID, body: String) async -> Bool {
        do {
            let userId = try getCurrentUserId()
            
            try await notesService.createNote(
                roomId: roomId,
                authorId: userId,
                body: body
            )
            
            return true
        } catch {
            handleError(error)
            return false
        }
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