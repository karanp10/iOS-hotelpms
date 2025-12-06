import Foundation

/// Combined membership + profile data for hotel employees
struct HotelEmployee: Codable, Identifiable, Equatable {
    let id: UUID               // hotel_memberships.id
    let profileId: UUID        // hotel_memberships.profile_id
    let hotelId: UUID          // hotel_memberships.hotel_id
    let role: HotelRole
    let status: MembershipStatus
    let createdAt: Date?
    let profile: Profile       // Nested profile data

    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case hotelId = "hotel_id"
        case role
        case status
        case createdAt = "created_at"
        case profile = "profiles"
    }

    var fullName: String {
        profile.fullName
    }

    var email: String {
        profile.email
    }

    var initials: String {
        let firstInitial = profile.firstName.prefix(1).uppercased()
        let lastInitial = profile.lastName.prefix(1).uppercased()
        return firstInitial + lastInitial
    }

    var isActive: Bool {
        status == .approved
    }

    var joinedDate: Date? {
        createdAt
    }

    func updatingRole(_ newRole: HotelRole) -> HotelEmployee {
        HotelEmployee(
            id: id,
            profileId: profileId,
            hotelId: hotelId,
            role: newRole,
            status: status,
            createdAt: createdAt,
            profile: profile
        )
    }

    static func == (lhs: HotelEmployee, rhs: HotelEmployee) -> Bool {
        lhs.id == rhs.id
    }
}
