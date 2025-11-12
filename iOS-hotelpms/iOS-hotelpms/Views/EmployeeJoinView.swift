import SwiftUI

struct EmployeeJoinView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var viewModel = EmployeeJoinViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        OnboardingFormContainer {
            VStack(spacing: AdaptiveLayout.sectionSpacing(horizontalSizeClass: horizontalSizeClass)) {
                FormHeader(
                    title: "Join a Hotel",
                    subtitle: "Search for and request to join an existing hotel"
                )
                
                VStack(spacing: 20) {
                    SearchBar(
                        searchText: $viewModel.hotelSearchText,
                        placeholder: "Enter hotel name...",
                        isLoading: viewModel.isSearching,
                        canSearch: viewModel.canSearch
                    ) {
                        Task {
                            await viewModel.searchHotels()
                        }
                    }
                    
                    if viewModel.hasSearchResults {
                        HotelSearchResults(
                            hotels: viewModel.availableHotels,
                            selectedHotel: viewModel.selectedHotel
                        ) { hotel in
                            viewModel.selectHotel(hotel)
                        }
                    }
                    
                    if viewModel.showJoinButton {
                        PrimaryButton(
                            title: viewModel.isLoading ? "Sending Request..." : "Request to Join",
                            isLoading: viewModel.isLoading,
                            isEnabled: !viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.requestToJoin()
                            }
                        }
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.top, 10)
                    }
                }
            }
        }
        .onAppear {
            viewModel.setNavigationManager(navigationManager)
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

#Preview {
    EmployeeJoinView()
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}