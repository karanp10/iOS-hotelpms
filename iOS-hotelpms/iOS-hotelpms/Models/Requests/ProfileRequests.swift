import Foundation

// MARK: - Profile Request Models

struct CreateProfileRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }
}