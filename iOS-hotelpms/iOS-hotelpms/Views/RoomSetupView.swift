import SwiftUI

struct RoomSetupView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var viewModel: RoomSetupViewModel
    
    init(hotelId: UUID) {
        self.hotelId = hotelId
        self._viewModel = StateObject(wrappedValue: RoomSetupViewModel(hotelId: hotelId))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    RoomSetupHeader(hotelName: viewModel.hotelName)
                    
                    // Room Ranges
                    VStack(alignment: .leading, spacing: 20) {
                        RoomRangesList(viewModel: viewModel)
                        
                        ValidationSummary(viewModel: viewModel)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: 600)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadHotelInfo()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("Retry") {
                viewModel.retryLoad()
            }
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Success!", isPresented: $viewModel.showingSuccess) {
            Button("Continue") {
                navigationManager.navigate(to: .roomDashboard(hotelId: hotelId))
            }
        } message: {
            Text(viewModel.getSuccessMessage())
        }
    }
}

#Preview {
    RoomSetupView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}