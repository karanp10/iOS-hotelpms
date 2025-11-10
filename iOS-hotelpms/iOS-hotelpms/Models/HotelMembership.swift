import Foundation

enum HotelRole: String, Codable, CaseIterable {
    case admin = "admin"
    case manager = "manager"
    case frontDesk = "front_desk"
    case housekeeping = "housekeeping"
    case maintenance = "maintenance"
    
    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .manager:
            return "Manager"
        case .frontDesk:
            return "Front Desk"
        case .housekeeping:
            return "Housekeeping"
        case .maintenance:
            return "Maintenance"
        }
    }
    
    var hasAdminAccess: Bool {
        return self == .admin || self == .manager
    }
}

enum MembershipStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        }
    }
}

struct HotelMembership: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    let hotelId: UUID
    let role: HotelRole
    let status: MembershipStatus
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case hotelId = "hotel_id"
        case role
        case status
        case createdAt = "created_at"
    }
}