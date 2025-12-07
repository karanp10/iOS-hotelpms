import Foundation

enum EmployeeTab: Hashable {
    case primary
    case activity
    case requests
    case account

    /// Returns the tab label text based on the user's role
    func label(for role: HotelRole) -> String {
        switch self {
        case .primary:
            switch role {
            case .housekeeping:
                return "My Rooms"
            case .maintenance:
                return "Issues"
            case .frontDesk, .manager:
                return "Board"
            case .admin:
                return "Dashboard" // Fallback, shouldn't be used
            }
        case .activity:
            return "Activity"
        case .requests:
            switch role {
            case .housekeeping:
                return "Queued"
            case .maintenance:
                return "Issues"
            case .frontDesk, .manager:
                return "Arrivals"
            case .admin:
                return "Requests" // Fallback
            }
        case .account:
            return "Account"
        }
    }

    /// Returns the tab icon based on the user's role
    func systemImage(for role: HotelRole) -> String {
        switch self {
        case .primary:
            switch role {
            case .housekeeping:
                return "sparkles"
            case .maintenance:
                return "wrench.and.screwdriver.fill"
            case .frontDesk, .manager:
                return "rectangle.grid.2x2.fill"
            case .admin:
                return "square.grid.2x2.fill" // Fallback
            }
        case .activity:
            return "clock.arrow.circlepath"
        case .requests:
            return "list.bullet.clipboard.fill"
        case .account:
            return "person.circle"
        }
    }

    static func defaultTab(for role: HotelRole) -> EmployeeTab {
        switch role {
        case .housekeeping:
            return .requests
        default:
            return .primary
        }
    }
}
