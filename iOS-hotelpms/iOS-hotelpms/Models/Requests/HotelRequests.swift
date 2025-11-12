import Foundation

// MARK: - Hotel Request Models

struct CreateHotelRequest: Codable {
    let name: String
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let createdBy: UUID
    
    enum CodingKeys: String, CodingKey {
        case name
        case address
        case city
        case state
        case zipCode = "zip_code"
        case createdBy = "created_by"
    }
}