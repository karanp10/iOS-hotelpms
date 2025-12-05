import Foundation
import SwiftUI

// MARK: - Mock Models for UI Development

struct JoinRequestMock: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let role: HotelRole
    let status: JoinRequestStatus
    let requestedDate: Date
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1).uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.prefix(1).uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
}

struct EmployeeMock: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let role: HotelRole
    let joinedDate: Date
    let isActive: Bool
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1).uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.prefix(1).uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
}

struct HotelSettingsMock {
    let checkoutTime: String
    let timezone: String
    let requireMaintenanceNotes: Bool
    let requireOOONotes: Bool
    let preventCleaningWithDND: Bool
    let autoDirtyHours: Int
    let autoStayoverEnabled: Bool
    let enabledFlags: [String]
}

struct RoomMock: Identifiable {
    let id = UUID()
    let roomNumber: Int
    let floorNumber: Int
    let type: String
    let isActive: Bool
}

struct UserMock {
    let name: String
    let email: String
    let role: HotelRole
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1).uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.prefix(1).uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
}

// MARK: - Mock Data Provider

struct MockData {
    
    // MARK: - Join Requests Mock Data
    static let joinRequests: [JoinRequestMock] = [
        JoinRequestMock(
            name: "Sarah Johnson",
            email: "sarah.johnson@email.com",
            role: .frontDesk,
            status: .pending,
            requestedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        ),
        JoinRequestMock(
            name: "Miguel Rodriguez",
            email: "miguel.r@email.com",
            role: .housekeeping,
            status: .pending,
            requestedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        ),
        JoinRequestMock(
            name: "Emily Chen",
            email: "emily.chen@email.com",
            role: .maintenance,
            status: .pending,
            requestedDate: Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
        ),
        JoinRequestMock(
            name: "David Kumar",
            email: "david.kumar@email.com",
            role: .manager,
            status: .pending,
            requestedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )
    ]
    
    // MARK: - Employees Mock Data
    static let employees: [EmployeeMock] = [
        // Managers
        EmployeeMock(
            name: "Alex Thompson",
            email: "alex.thompson@hotel.com",
            role: .manager,
            joinedDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
            isActive: true
        ),
        EmployeeMock(
            name: "Lisa Park",
            email: "lisa.park@hotel.com",
            role: .admin,
            joinedDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
            isActive: true
        ),
        
        // Front Desk
        EmployeeMock(
            name: "Jordan Smith",
            email: "jordan.smith@hotel.com",
            role: .frontDesk,
            joinedDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            isActive: true
        ),
        EmployeeMock(
            name: "Taylor Wilson",
            email: "taylor.wilson@hotel.com",
            role: .frontDesk,
            joinedDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date(),
            isActive: true
        ),
        
        // Housekeeping
        EmployeeMock(
            name: "Maria Garcia",
            email: "maria.garcia@hotel.com",
            role: .housekeeping,
            joinedDate: Calendar.current.date(byAdding: .month, value: -4, to: Date()) ?? Date(),
            isActive: true
        ),
        EmployeeMock(
            name: "James Lee",
            email: "james.lee@hotel.com",
            role: .housekeeping,
            joinedDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            isActive: true
        ),
        
        // Maintenance
        EmployeeMock(
            name: "Robert Davis",
            email: "robert.davis@hotel.com",
            role: .maintenance,
            joinedDate: Calendar.current.date(byAdding: .month, value: -5, to: Date()) ?? Date(),
            isActive: true
        )
    ]
    
    // MARK: - Hotel Settings Mock Data
    static let hotelSettings = HotelSettingsMock(
        checkoutTime: "11:00 AM",
        timezone: "Eastern Time (EST)",
        requireMaintenanceNotes: true,
        requireOOONotes: true,
        preventCleaningWithDND: true,
        autoDirtyHours: 2,
        autoStayoverEnabled: true,
        enabledFlags: ["VIP", "Rush", "DND", "Maintenance"]
    )
    
    // MARK: - Rooms Mock Data
    static let rooms: [RoomMock] = [
        RoomMock(roomNumber: 101, floorNumber: 1, type: "Standard", isActive: true),
        RoomMock(roomNumber: 102, floorNumber: 1, type: "Standard", isActive: true),
        RoomMock(roomNumber: 103, floorNumber: 1, type: "Suite", isActive: true),
        RoomMock(roomNumber: 201, floorNumber: 2, type: "Standard", isActive: true),
        RoomMock(roomNumber: 202, floorNumber: 2, type: "Standard", isActive: false),
        RoomMock(roomNumber: 301, floorNumber: 3, type: "Deluxe", isActive: true),
    ]
    
    // MARK: - Current User Mock Data
    static let currentUser = UserMock(
        name: "John Manager",
        email: "john.manager@hotel.com",
        role: .manager
    )
    
    // MARK: - Helper Functions
    static var employeesByRole: [HotelRole: [EmployeeMock]] {
        Dictionary(grouping: employees) { $0.role }
    }
    
    static var roomsByFloor: [Int: [RoomMock]] {
        Dictionary(grouping: rooms) { $0.floorNumber }
    }
}