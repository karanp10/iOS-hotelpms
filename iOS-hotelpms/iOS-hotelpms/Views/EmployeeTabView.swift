import SwiftUI

struct EmployeeTabView: View {
    let hotelId: UUID
    let userRole: HotelRole
    @State private var selectedTab: EmployeeTab
    @EnvironmentObject var navigationManager: NavigationManager

    init(hotelId: UUID, userRole: HotelRole) {
        self.hotelId = hotelId
        self.userRole = userRole
        _selectedTab = State(initialValue: EmployeeTab.defaultTab(for: userRole))
    }

    var body: some View {
        if userRole == .housekeeping {
            TabView(selection: $selectedTab) {
                // Queued first for housekeeping
                requestsTabContent
                    .tabItem {
                        Label(
                            EmployeeTab.requests.label(for: userRole),
                            systemImage: EmployeeTab.requests.systemImage(for: userRole)
                        )
                    }
                    .tag(EmployeeTab.requests)

                // Activity second
                activityTabContent
                    .tabItem {
                        Label(
                            EmployeeTab.activity.label(for: userRole),
                            systemImage: EmployeeTab.activity.systemImage(for: userRole)
                        )
                    }
                    .tag(EmployeeTab.activity)

                // Board/My Rooms third
                primaryTabContent
                    .tabItem {
                        Label(
                            EmployeeTab.primary.label(for: userRole),
                            systemImage: EmployeeTab.primary.systemImage(for: userRole)
                        )
                    }
                    .tag(EmployeeTab.primary)

                // Account stays last
                AccountSettingsView()
                    .tabItem {
                        Label(
                            EmployeeTab.account.label(for: userRole),
                            systemImage: EmployeeTab.account.systemImage(for: userRole)
                        )
                    }
                    .tag(EmployeeTab.account)
            }
            .navigationBarHidden(true)
        } else {
            TabView(selection: $selectedTab) {
                // Primary Tab (Role-Specific)
                primaryTabContent
                    .tabItem {
                        Label(
                            EmployeeTab.primary.label(for: userRole),
                            systemImage: EmployeeTab.primary.systemImage(for: userRole)
                        )
                    }
                    .tag(EmployeeTab.primary)

                // Activity Tab (Filtered Recent Updates)
                activityTabContent
                    .tabItem {
                        Label(
                            EmployeeTab.activity.label(for: userRole),
                            systemImage: EmployeeTab.activity.systemImage(for: userRole)
                        )
                    }
                    .tag(EmployeeTab.activity)

                // Requests/Tasks Tab (Queued Work)
                requestsTabContent
                    .tabItem {
                        Label(
                            EmployeeTab.requests.label(for: userRole),
                            systemImage: EmployeeTab.requests.systemImage(for: userRole)
                        )
                    }
                    .tag(EmployeeTab.requests)

                // Account Tab
                AccountSettingsView()
                    .tabItem {
                        Label(
                            EmployeeTab.account.label(for: userRole),
                            systemImage: EmployeeTab.account.systemImage(for: userRole)
                        )
                    }
                    .tag(EmployeeTab.account)
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Tab Content Views

    @ViewBuilder
    private var primaryTabContent: some View {
        switch userRole {
        case .housekeeping:
            HousekeepingBoardView(hotelId: hotelId)
        case .maintenance:
            // TODO: Replace with MaintenanceIssuesView
            placeholderView(title: "Issues", subtitle: "Maintenance workspace")
        case .frontDesk, .manager:
            // TODO: Replace with FrontDeskBoardView
            placeholderView(title: "Board", subtitle: "Front desk workspace")
        case .admin:
            // Admins should use AdminTabView instead
            placeholderView(title: "Admin", subtitle: "Use AdminTabView")
        }
    }

    @ViewBuilder
    private var activityTabContent: some View {
        switch userRole {
        case .housekeeping:
            HousekeepingActivityView(hotelId: hotelId)
        default:
            placeholderView(title: "Activity", subtitle: "Recent updates filtered by role")
        }
    }

    @ViewBuilder
    private var requestsTabContent: some View {
        switch userRole {
        case .housekeeping:
            HousekeepingQueueView(hotelId: hotelId)
        case .maintenance:
            // TODO: Replace with MaintenanceQueueView
            placeholderView(title: "Open Issues", subtitle: "Maintenance tasks")
        case .frontDesk, .manager:
            // TODO: Replace with FrontDeskQueueView
            placeholderView(title: "Arrivals/Departures", subtitle: "Expected guests")
        case .admin:
            placeholderView(title: "Requests", subtitle: "Use AdminTabView")
        }
    }

    // MARK: - Placeholder Helper

    private func placeholderView(title: String, subtitle: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(title)
                .font(.title)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Coming soon...")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmployeeTabView(hotelId: UUID(), userRole: .housekeeping)
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}
