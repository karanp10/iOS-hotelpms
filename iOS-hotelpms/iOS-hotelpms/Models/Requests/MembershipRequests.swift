import Foundation

// MARK: - Membership Request Models

struct CreateMembershipRequest: Codable {
    let profileId: UUID
    let hotelId: UUID
    let role: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case hotelId = "hotel_id"
        case role
        case status
    }
}

struct CreateJoinRequest: Codable {
    let profileId: UUID
    let hotelId: UUID
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case hotelId = "hotel_id"
        case status
    }
}