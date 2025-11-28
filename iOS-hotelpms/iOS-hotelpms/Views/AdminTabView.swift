import SwiftUI

struct AdminTabView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var dashboardCoordinator = AdminDashboardCoordinator()
    
    private var statusTabLabel: some View {
        Label("Status", systemImage: "bed.double.fill")
    }
    
    private var updatesTabLabel: some View {
        Label("Recent Updates", systemImage: "clock.arrow.circlepath")
    }
    
    private var adminTabLabel: some View {
        Label("Admin", systemImage: "gear")
    }
    
    private var accountTabLabel: some View {
        Label("Account", systemImage: "person.circle")
    }
    
    var body: some View {
        TabView(selection: $dashboardCoordinator.selectedTab) {
            // Status Tab
            RoomDashboardView(hotelId: hotelId)
                .environment(\.dashboardCoordinator, dashboardCoordinator)
                .tabItem { statusTabLabel }
                .tag(AdminTab.status)
            
            // Recent Updates Tab
            RecentlyUpdatedView(hotelId: hotelId)
                .environment(\.dashboardCoordinator, dashboardCoordinator)
                .tabItem { updatesTabLabel }
                .tag(AdminTab.recentUpdates)
            
            // Admin Tab (placeholder)
            AdminManagementView(hotelId: hotelId)
                .environment(\.dashboardCoordinator, dashboardCoordinator)
                .tabItem { adminTabLabel }
                .tag(AdminTab.admin)
            
            // Account Tab (placeholder)
            AccountSettingsView()
                .environment(\.dashboardCoordinator, dashboardCoordinator)
                .tabItem { accountTabLabel }
                .tag(AdminTab.account)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AdminTabView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}
