import Foundation
import Supabase
import PostgREST

// MARK: - Hotel Service Errors

enum HotelServiceError: LocalizedError {
    case hotelCreationFailed(String)
    case userNotAuthenticated
    case networkError(String)
    case hotelNotFound
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .hotelCreationFailed(let message):
            return "Failed to create hotel: \(message)"
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        case .networkError(let message):
            return "Network error: \(message)"
        case .hotelNotFound:
            return "Hotel not found"
        case .accessDenied:
            return "Access denied to this hotel"
        }
    }
}

// MARK: - Hotel Service

class HotelService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    /// Creates a hotel record
    func createHotel(
        name: String,
        address: String?,
        city: String?,
        state: String?,
        zipCode: String?
    ) async throws -> Hotel {
        guard let userId = supabase.auth.currentUser?.id else {
            throw HotelServiceError.userNotAuthenticated
        }
        
        let request = CreateHotelRequest(
            name: name,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode,
            createdBy: userId
        )
        
        do {
            let response: [Hotel] = try await supabase
                .from("hotels")
                .insert(request)
                .select()
                .execute()
                .value
            
            guard let hotel = response.first else {
                throw HotelServiceError.hotelCreationFailed("No hotel returned from server")
            }
            
            return hotel
        } catch {
            throw HotelServiceError.hotelCreationFailed(error.localizedDescription)
        }
    }
    
    /// Gets all hotels created by the authenticated user
    func getUserHotels() async throws -> [Hotel] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw HotelServiceError.userNotAuthenticated
        }
        
        do {
            let response: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .eq("created_by", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw HotelServiceError.networkError(error.localizedDescription)
        }
    }
    
    /// Gets a specific hotel by ID (with authorization check)
    func getHotel(id: UUID) async throws -> Hotel {
        guard let userId = supabase.auth.currentUser?.id else {
            throw HotelServiceError.userNotAuthenticated
        }
        
        do {
            let response: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .eq("id", value: id)
                .eq("created_by", value: userId)
                .execute()
                .value
            
            guard let hotel = response.first else {
                throw HotelServiceError.accessDenied
            }
            
            return hotel
        } catch {
            throw HotelServiceError.networkError(error.localizedDescription)
        }
    }
    
    /// Search hotels by name
    func searchHotels(query: String) async throws -> [Hotel] {
        let searchQuery = "%\(query)%"
        
        do {
            let response: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .ilike("name", pattern: searchQuery)
                .limit(10)
                .execute()
                .value
            
            return response
        } catch {
            throw HotelServiceError.networkError("Failed to search hotels: \(error.localizedDescription)")
        }
    }
    
    /// Gets all hotels for the user with their room counts
    func getUserHotelsWithRoomCounts() async throws -> [HotelWithRoomCount] {
        guard let userId = supabase.auth.currentUser?.id else {
            throw HotelServiceError.userNotAuthenticated
        }
        
        do {
            // First get user's hotels via membership
            let membershipResponse: [[String: AnyJSON]] = try await supabase
                .from("hotel_memberships")
                .select("hotel_id")
                .eq("profile_id", value: userId)
                .eq("status", value: "approved")
                .execute()
                .value
            
            let hotelIds = membershipResponse.compactMap { dict -> String? in
                dict["hotel_id"]?.stringValue
            }
            
            guard !hotelIds.isEmpty else {
                return []
            }
            
            // Get hotel details
            let hotelsResponse: [Hotel] = try await supabase
                .from("hotels")
                .select()
                .in("id", values: hotelIds)
                .execute()
                .value
            
            // Get room counts for each hotel
            var hotelsWithRoomCount: [HotelWithRoomCount] = []
            for hotel in hotelsResponse {
                let roomCount = try await getRoomCount(hotelId: hotel.id)
                
                hotelsWithRoomCount.append(HotelWithRoomCount(
                    id: hotel.id,
                    name: hotel.name,
                    address: hotel.address,
                    city: hotel.city,
                    state: hotel.state,
                    zipCode: hotel.zipCode,
                    createdAt: hotel.createdAt ?? Date(),
                    roomCount: roomCount
                ))
            }
            
            return hotelsWithRoomCount
        } catch {
            throw HotelServiceError.networkError("Failed to get hotels with room counts: \(error.localizedDescription)")
        }
    }
    
    /// Gets room count for a specific hotel
    func getRoomCount(hotelId: UUID) async throws -> Int {
        do {
            let response: [[String: AnyJSON]] = try await supabase
                .from("rooms")
                .select("id")
                .eq("hotel_id", value: hotelId)
                .execute()
                .value
            
            return response.count
        } catch {
            throw HotelServiceError.networkError("Failed to get room count: \(error.localizedDescription)")
        }
    }
}