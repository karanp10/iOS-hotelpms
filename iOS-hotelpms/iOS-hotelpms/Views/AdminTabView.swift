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
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AdminTabView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}
