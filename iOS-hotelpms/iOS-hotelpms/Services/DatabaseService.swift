import Foundation
import Supabase
import PostgREST

@available(*, deprecated, message: "DatabaseService is deprecated. Use domain-specific services: ProfileService, HotelService, MembershipService, RoomBatchService")
enum DatabaseError: LocalizedError {
    case profileCreationFailed(String)
    case hotelCreationFailed(String)
    case userNotAuthenticated
    case networkError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .profileCreationFailed(let message):
            return "Failed to create profile: \(message)"
        case .hotelCreationFailed(let message):
            return "Failed to create hotel: \(message)"
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

@available(*, deprecated, message: "DatabaseService is deprecated. Use domain-specific services: ProfileService, HotelService, MembershipService, RoomBatchService")
class DatabaseService: ObservableObject {
    // This class has been deprecated and split into domain-specific services:
    // - ProfileService: Profile CRUD operations
    // - HotelService: Hotel CRUD and metadata operations
    // - MembershipService: Membership and join request operations
    // - RoomBatchService: Room bulk creation operations
    // 
    // The duplicated getRooms method has been removed as it exists in RoomService.
    // Please update your code to use the appropriate domain service.
}
