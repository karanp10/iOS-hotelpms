import Foundation
import SwiftUI

@MainActor
class RoomSetupViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var hotelName = ""
    @Published var roomRanges: [RoomRange] = [RoomRange()]
    
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingSuccess = false
    
    // MARK: - Dependencies
    private let hotelId: UUID
    private let hotelService: HotelService
    private let roomBatchService: RoomBatchService
    
    // MARK: - Computed Properties
    var totalRoomCount: Int {
        roomRanges.totalRoomCount
    }
    
    var hasOverlappingRanges: Bool {
        roomRanges.hasOverlappingRanges
    }
    
    var isFormValid: Bool {
        roomRanges.isValidConfiguration
    }
    
    var validRangesDisplayText: String {
        roomRanges.validRangesDisplayText
    }
    
    var hasValidRanges: Bool {
        !roomRanges.validRanges.isEmpty
    }
    
    // MARK: - Initialization
    init(hotelId: UUID, hotelService: HotelService = HotelService(), roomBatchService: RoomBatchService = RoomBatchService()) {
        self.hotelId = hotelId
        self.hotelService = hotelService
        self.roomBatchService = roomBatchService
    }
    
    // MARK: - Public Methods
    func loadHotelInfo() async {
        do {
            let hotel = try await hotelService.getHotel(id: hotelId)
            hotelName = hotel.name
        } catch {
            errorMessage = "Failed to load hotel information: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    func addRange() {
        roomRanges.append(RoomRange())
    }
    
    func removeRange(at index: Int) {
        guard roomRanges.count > 1 && index < roomRanges.count else { return }
        roomRanges.remove(at: index)
    }
    
    func updateRange(at index: Int, with range: RoomRange) {
        guard index < roomRanges.count else { return }
        roomRanges[index] = range
    }
    
    func createRooms() async {
        guard isFormValid else { return }
        
        isLoading = true
        
        do {
            try await roomBatchService.createRooms(hotelId: hotelId, ranges: roomRanges, hotelService: hotelService)
            showingSuccess = true
        } catch {
            errorMessage = "Failed to create rooms: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    func retryLoad() {
        Task { await loadHotelInfo() }
    }
    
    func getSuccessMessage() -> String {
        return "Successfully created \(totalRoomCount) rooms for \(hotelName)!"
    }
    
    var canDeleteRange: Bool {
        roomRanges.count > 1
    }
}