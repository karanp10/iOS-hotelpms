//
//  ContentView.swift
//  
//
//  Created by Karan Patel on 9/9/25.
//

import SwiftUI

enum NavigationDestination: Hashable {
    case accountSelection
    case personalInfo
    case accountSuccess(email: String)
    case emailVerification(email: String)
    case managerHotelSetup
    case employeeJoin
    case joinRequestPending(hotelName: String)
    case hotelSelection
    case roomSetup(hotelId: UUID)
    case roomDashboard(hotelId: UUID, roomId: UUID? = nil)
    case adminDashboard(hotelId: UUID)
    case employeeDashboard(hotelId: UUID, userRole: HotelRole)
}


struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            LoginView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .accountSelection:
                        AccountSelectionView()
                    case .personalInfo:
                        PersonalInfoView()
                    case .accountSuccess(let email):
                        AccountSuccessView(userEmail: email)
                    case .emailVerification(let email):
                        EmailVerificationView(userEmail: email)
                    case .managerHotelSetup:
                        ManagerHotelSetupView()
                    case .employeeJoin:
                        EmployeeJoinView()
                    case .joinRequestPending(let hotelName):
                        JoinRequestPendingView(hotelName: hotelName)
                    case .hotelSelection:
                        HotelSelectionView()
                    case .roomSetup(let hotelId):
                        RoomSetupView(hotelId: hotelId)
                    case .roomDashboard(let hotelId, let roomId):
                        RoomDashboardView(hotelId: hotelId, initialRoomId: roomId)
                    case .adminDashboard(let hotelId):
                        AdminTabView(hotelId: hotelId)
                    case .employeeDashboard(let hotelId, let userRole):
                        EmployeeTabView(hotelId: hotelId, userRole: userRole)
                    }
                }
        }
        .environmentObject(NavigationManager(path: $navigationPath))
    }
}

class NavigationManager: ObservableObject {
    @Binding var path: NavigationPath
    
    init(path: Binding<NavigationPath>) {
        self._path = path
    }
    
    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
    }
}

#Preview {
    ContentView()
}
