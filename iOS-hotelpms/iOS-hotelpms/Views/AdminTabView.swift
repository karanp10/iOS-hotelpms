import SwiftUI

struct AdminTabView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        TabView {
            // Status Tab
            RoomDashboardView(hotelId: hotelId)
                .tabItem {
                    Image(systemName: "bed.double.fill")
                    Text("Status")
                }
            
            // Recent Updates Tab
            RecentlyUpdatedView(hotelId: hotelId)
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Recent Updates")
                }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AdminTabView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}