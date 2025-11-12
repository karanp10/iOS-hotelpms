import SwiftUI

struct PersonalInfoView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var viewModel: PersonalInfoViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init() {
        self._viewModel = StateObject(wrappedValue: PersonalInfoViewModel())
    }
    
    var body: some View {
        OnboardingFormContainer {
            VStack(spacing: AdaptiveLayout.sectionSpacing(horizontalSizeClass: horizontalSizeClass)) {
                FormHeader(
                    title: "Personal Information",
                    subtitle: "Tell us about yourself"
                )
                
                VStack(spacing: AdaptiveLayout.sectionSpacing(horizontalSizeClass: horizontalSizeClass)) {
                    HStack(spacing: 12) {
                        TextField("First Name", text: $viewModel.firstName)
                            .textFieldStyle(.roundedBorder)
                            .frame(height: 44)
                        
                        TextField("Last Name", text: $viewModel.lastName)
                            .textFieldStyle(.roundedBorder)
                            .frame(height: 44)
                    }
                    
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .frame(height: 44)
                    
                    PasswordFields(
                        password: $viewModel.password,
                        confirmPassword: $viewModel.confirmPassword
                    )
                }
                
                PrimaryButton(
                    title: viewModel.isLoading ? "Creating Account..." : "Create Account",
                    isLoading: viewModel.isLoading,
                    isEnabled: viewModel.isFormValid
                ) {
                    Task {
                        await viewModel.createAccount()
                    }
                }
            }
        }
        .onAppear {
            viewModel.setNavigationManager(navigationManager)
        }
        .alert("Validation Error", isPresented: $viewModel.showingAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

#Preview {
    PersonalInfoView()
}
