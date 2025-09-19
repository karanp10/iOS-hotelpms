import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case createdAt = "created_at"
    }
    
    // Computed property for full name
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}