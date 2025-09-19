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
    case hotelInfo(personalData: PersonalData)
    case accountSuccess(email: String)
    case emailVerification(email: String)
    case managerHotelSetup
    case employeeJoin
}

struct PersonalData: Hashable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
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
                    case .hotelInfo(let personalData):
                        HotelInfoView(personalData: personalData)
                    case .accountSuccess(let email):
                        AccountSuccessView(userEmail: email)
                    case .emailVerification(let email):
                        EmailVerificationView(userEmail: email)
                    case .managerHotelSetup:
                        ManagerHotelSetupView()
                    case .employeeJoin:
                        EmployeeJoinView()
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
