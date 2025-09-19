import SwiftUI

struct EmailVerificationView: View {
    let userEmail: String
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(spacing: 32) {
                    // Icon
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 16) {
                        Text("Check Your Email")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("We've sent a verification link to:")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text(userEmail)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Please check your email and click the verification link to activate your account.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("After verifying your email, return here and sign in to complete your setup.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        // Navigate back to login
                        navigationManager.navigateToRoot()
                    }) {
                        Text("Continue to Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .frame(width: min(400, geometry.size.width * 0.8))
                .padding(40)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    EmailVerificationView(userEmail: "john@example.com")
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}