import SwiftUI

struct JoinRequestPendingView: View {
    let hotelName: String
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        OnboardingFormContainer {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)

                VStack(spacing: 16) {
                    // Title
                    Text("Request Pending")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    // Subtitle with hotel name
                    Text("Your request to join")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text(hotelName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("is being reviewed")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Info card
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(
                        icon: "person.badge.shield.checkmark",
                        text: "A manager will review your request"
                    )

                    InfoRow(
                        icon: "envelope.badge",
                        text: "You'll receive an email when approved"
                    )

                    InfoRow(
                        icon: "app.badge",
                        text: "You can then log in and start working"
                    )
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                Spacer()

                // Back to login button
                PrimaryButton(
                    title: "Back to Login",
                    action: {
                        navigationManager.navigateToRoot()
                    }
                )
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        JoinRequestPendingView(hotelName: "Grand Plaza Hotel")
            .environmentObject(NavigationManager(path: .constant(NavigationPath())))
    }
}
