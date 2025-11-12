import SwiftUI

struct ManagerHotelSetupView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var viewModel = ManagerHotelSetupViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @FocusState private var focusedField: ManagerHotelSetupViewModel.Field?
    
    var body: some View {
        OnboardingFormContainer {
            VStack(spacing: AdaptiveLayout.sectionSpacing(horizontalSizeClass: horizontalSizeClass)) {
                FormHeader(
                    title: "Create Your Hotel",
                    subtitle: "Set up your hotel business details"
                )
                
                VStack(spacing: AdaptiveLayout.sectionSpacing(horizontalSizeClass: horizontalSizeClass)) {
                    BasicInfoFields(
                        hotelName: $viewModel.hotelName,
                        phoneNumber: $viewModel.phoneNumber,
                        focusedField: $focusedField
                    )
                    
                    LocationFields(
                        address: $viewModel.address,
                        city: $viewModel.city,
                        state: $viewModel.state,
                        zipCode: $viewModel.zipCode,
                        focusedField: $focusedField
                    )
                }
                
                PrimaryButton(
                    title: viewModel.isLoading ? "Creating Hotel..." : "Create Hotel",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.isFormValid
                ) {
                    Task {
                        await viewModel.createHotelAndMembership()
                    }
                }
                .padding(.top, 20)
            }
        }
        .onAppear {
            viewModel.setNavigationManager(navigationManager)
        }
        .onTapGesture {
            focusedField = nil
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

#Preview {
    ManagerHotelSetupView()
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}