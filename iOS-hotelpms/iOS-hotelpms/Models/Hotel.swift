import Foundation

struct Hotel: Codable, Identifiable {
    let id: UUID
    let name: String
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let createdBy: UUID
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case city
        case state
        case zipCode = "zip_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    // Computed property for full address
    var fullAddress: String {
        var addressComponents: [String] = []
        
        if let address = address, !address.isEmpty {
            addressComponents.append(address)
        }
        
        var cityStateZip: [String] = []
        if let city = city, !city.isEmpty {
            cityStateZip.append(city)
        }
        if let state = state, !state.isEmpty {
            cityStateZip.append(state)
        }
        if let zipCode = zipCode, !zipCode.isEmpty {
            cityStateZip.append(zipCode)
        }
        
        if !cityStateZip.isEmpty {
            addressComponents.append(cityStateZip.joined(separator: ", "))
        }
        
        return addressComponents.joined(separator: "\n")
    }
}