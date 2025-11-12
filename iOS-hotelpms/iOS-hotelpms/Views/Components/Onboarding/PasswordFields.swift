import SwiftUI

struct PasswordFields: View {
    @Binding var password: String
    @Binding var confirmPassword: String
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad: Side-by-side password fields
            HStack(spacing: 12) {
                passwordField
                confirmPasswordField
            }
        } else {
            // iPhone: Stacked password fields
            VStack(spacing: 16) {
                passwordField
                confirmPasswordField
            }
        }
    }
    
    private var passwordField: some View {
        SecureField("Password", text: $password)
            .textFieldStyle(.roundedBorder)
            .textContentType(.newPassword)
            .frame(height: 44)
            .autocorrectionDisabled()
    }
    
    private var confirmPasswordField: some View {
        SecureField("Confirm Password", text: $confirmPassword)
            .textFieldStyle(.roundedBorder)
            .textContentType(.newPassword)
            .frame(height: 44)
            .autocorrectionDisabled()
    }
}