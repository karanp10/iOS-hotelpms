import Foundation
import SwiftUI
import Combine

enum AdminTab: Hashable {
    case status
    case recentUpdates
}

/// Coordinates tab selection and deep-linking between the dashboard and recent updates screens.
final class AdminDashboardCoordinator: ObservableObject {
    @Published var selectedTab: AdminTab = .status
    @Published var requestedRoomId: UUID?
    
    func focusRoom(_ roomId: UUID) {
        requestedRoomId = roomId
    }
    
    func clearRoomRequest() {
        requestedRoomId = nil
    }
}

private struct AdminDashboardCoordinatorKey: EnvironmentKey {
    static let defaultValue: AdminDashboardCoordinator? = nil
}

extension EnvironmentValues {
    var dashboardCoordinator: AdminDashboardCoordinator? {
        get { self[AdminDashboardCoordinatorKey.self] }
        set { self[AdminDashboardCoordinatorKey.self] = newValue }
    }
}
