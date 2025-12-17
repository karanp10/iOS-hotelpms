import Foundation

@MainActor
final class HousekeepingActivityViewModel: ObservableObject {
    enum ActivityScope: String, CaseIterable {
        case mine = "My Activity"
        case team = "Team Activity"
    }

    // MARK: - Dependencies
    private let serviceManager: ServiceManager
    private let hotelId: UUID

    // MARK: - Published State
    @Published var scope: ActivityScope = .mine
    @Published var myActivity: [RoomHistoryEntry] = []
    @Published var teamActivity: [RoomHistoryEntry] = []
    @Published var isLoading = false
    @Published var error: String?

    init(serviceManager: ServiceManager = .shared, hotelId: UUID) {
        self.serviceManager = serviceManager
        self.hotelId = hotelId
    }

    func loadActivity() async {
        guard let currentUser = serviceManager.currentUserId else {
            error = "User not authenticated"
            return
        }

        isLoading = true
        error = nil

        do {
            async let myFeed = serviceManager.roomHistoryService.getActivityByActor(actorId: currentUser)
            async let teamFeed = serviceManager.roomHistoryService.getRecentHistoryForHotel(hotelId: hotelId)

            let (myEntries, teamEntries) = try await (myFeed, teamFeed)
            myActivity = myEntries
            teamActivity = teamEntries
        } catch {
            self.error = "Failed to load activity: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refresh() async {
        await loadActivity()
    }
}
