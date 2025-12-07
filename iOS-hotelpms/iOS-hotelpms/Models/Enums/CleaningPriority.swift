import Foundation

/// Represents the cleaning priority for rooms based on occupancy and cleaning status
enum CleaningPriority: Int, Comparable {
    case high = 3       // Checked out rooms - need immediate cleaning
    case medium = 2     // Dirty rooms - need cleaning
    case low = 1        // Cleaning in progress - being worked on
    case none = 0       // Ready rooms - no cleaning needed

    static func < (lhs: CleaningPriority, rhs: CleaningPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .high:
            return "High Priority"
        case .medium:
            return "Medium Priority"
        case .low:
            return "In Progress"
        case .none:
            return "Ready"
        }
    }

    var color: String {
        switch self {
        case .high:
            return "red"
        case .medium:
            return "orange"
        case .low:
            return "yellow"
        case .none:
            return "green"
        }
    }

    /// Determines cleaning priority for a room based on occupancy and cleaning status
    static func priority(for room: Room) -> CleaningPriority {
        // Checked out rooms have highest priority
        if room.occupancyStatus == .checkedOut {
            return .high
        }

        // Then prioritize by cleaning status
        switch room.cleaningStatus {
        case .dirty:
            return .medium
        case .cleaningInProgress:
            return .low
        case .ready:
            return .none
        }
    }
}
