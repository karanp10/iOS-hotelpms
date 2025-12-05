import Foundation

// MARK: - Join Request Status

enum JoinRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .rejected:
            return "Rejected"
        }
    }

    /// Translates join_requests status to hotel_memberships status
    func toMembershipStatus() -> MembershipStatus {
        switch self {
        case .pending:
            return .pending
        case .accepted:
            return .approved  // Translation: accepted → approved
        case .rejected:
            return .rejected
        }
    }
}

// MARK: - Join Request Model

struct JoinRequest: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    let hotelId: UUID
    let status: JoinRequestStatus
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case hotelId = "hotel_id"
        case status
        case createdAt = "created_at"
    }

    // Custom decoding to handle status enum
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        profileId = try container.decode(UUID.self, forKey: .profileId)
        hotelId = try container.decode(UUID.self, forKey: .hotelId)

        let statusRawValue = try container.decode(String.self, forKey: .status)
        status = JoinRequestStatus(rawValue: statusRawValue) ?? .pending

        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(profileId, forKey: .profileId)
        try container.encode(hotelId, forKey: .hotelId)
        try container.encode(status.rawValue, forKey: .status)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }

    // Initializer for creating new requests
    init(
        id: UUID = UUID(),
        profileId: UUID,
        hotelId: UUID,
        status: JoinRequestStatus = .pending,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.profileId = profileId
        self.hotelId = hotelId
        self.status = status
        self.createdAt = createdAt
    }
}

// MARK: - Join Request With Profile (for Admin Views)

/// Join request with nested profile data for admin approval UI
struct JoinRequestWithProfile: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    let hotelId: UUID
    let status: JoinRequestStatus
    let createdAt: Date?
    let profile: Profile

    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case hotelId = "hotel_id"
        case status
        case createdAt = "created_at"
        case profile = "profiles"  // Supabase nested join uses table name
    }

    // Regular initializer
    init(
        id: UUID = UUID(),
        profileId: UUID,
        hotelId: UUID,
        status: JoinRequestStatus = .pending,
        createdAt: Date? = nil,
        profile: Profile
    ) {
        self.id = id
        self.profileId = profileId
        self.hotelId = hotelId
        self.status = status
        self.createdAt = createdAt
        self.profile = profile
    }

    // Custom decoding to handle status enum
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        profileId = try container.decode(UUID.self, forKey: .profileId)
        hotelId = try container.decode(UUID.self, forKey: .hotelId)

        let statusRawValue = try container.decode(String.self, forKey: .status)
        status = JoinRequestStatus(rawValue: statusRawValue) ?? .pending

        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        profile = try container.decode(Profile.self, forKey: .profile)
    }

    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(profileId, forKey: .profileId)
        try container.encode(hotelId, forKey: .hotelId)
        try container.encode(status.rawValue, forKey: .status)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(profile, forKey: .profile)
    }

    // Computed properties for UI convenience
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
}
