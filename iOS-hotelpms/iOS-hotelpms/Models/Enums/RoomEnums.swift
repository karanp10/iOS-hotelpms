import Foundation

// MARK: - Room Status Enums

enum OccupancyStatus: String, CaseIterable, Codable {
    case vacant = "vacant"
    case assigned = "assigned"
    case occupied = "occupied"
    case stayover = "stayover"
    case checkedOut = "checked_out"
    
    var displayName: String {
        switch self {
        case .vacant: return "Vacant"
        case .assigned: return "Assigned"
        case .occupied: return "Occupied"
        case .stayover: return "Stayover"
        case .checkedOut: return "Checked Out"
        }
    }
    
    var color: String {
        switch self {
        case .vacant: return "gray"
        case .assigned: return "blue"
        case .occupied: return "green"
        case .stayover: return "orange"
        case .checkedOut: return "red"
        }
    }
}

enum CleaningStatus: String, CaseIterable, Codable {
    case dirty = "dirty"
    case cleaningInProgress = "cleaning_in_progress"
    case ready = "ready"
    
    var displayName: String {
        switch self {
        case .dirty: return "Dirty"
        case .cleaningInProgress: return "Cleaning"
        case .ready: return "Ready"
        }
    }
    
    var color: String {
        switch self {
        case .dirty: return "red"
        case .cleaningInProgress: return "yellow"
        case .ready: return "green"
        }
    }
    
    var systemImage: String {
        switch self {
        case .dirty: return "exclamationmark.triangle.fill"
        case .cleaningInProgress: return "clock.fill"
        case .ready: return "checkmark.circle.fill"
        }
    }
}

enum RoomFlag: String, CaseIterable, Codable {
    case maintenanceRequired = "maintenance_required"
    case outOfOrder = "out_of_order"
    case outOfService = "out_of_service"
    case dnd = "dnd"
    
    var displayName: String {
        switch self {
        case .maintenanceRequired: return "Maintenance"
        case .outOfOrder: return "OOO"
        case .outOfService: return "OOS"
        case .dnd: return "DND"
        }
    }
    
    var color: String {
        switch self {
        case .maintenanceRequired: return "orange"
        case .outOfOrder: return "red"
        case .outOfService: return "red"
        case .dnd: return "purple"
        }
    }
    
    var systemImage: String {
        switch self {
        case .maintenanceRequired: return "wrench.fill"
        case .outOfOrder: return "xmark.circle.fill"
        case .outOfService: return "minus.circle.fill"
        case .dnd: return "moon.fill"
        }
    }
}