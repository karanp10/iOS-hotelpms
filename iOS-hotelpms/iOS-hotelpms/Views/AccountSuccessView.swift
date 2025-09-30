//
//  AccountSuccessView.swift
//  iOS-hotelpms
//
//  Created by Karan Patel on 9/11/25.
//

import SwiftUI

struct AccountSuccessView: View {
    let userEmail: String
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                
                VStack(spacing: AdaptiveLayout.verticalSpacing(horizontalSizeClass: horizontalSizeClass)) {
                    Spacer()
                        .frame(minHeight: AdaptiveLayout.topPadding(horizontalSizeClass: horizontalSizeClass))
                    
                    VStack(spacing: AdaptiveLayout.verticalSpacing(horizontalSizeClass: horizontalSizeClass)) {
                    // Success Icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    
                    VStack(spacing: 16) {
                        Text("Account Created Successfully!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("We're setting up your hotel management system")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 16) {
                        Text("📧 Verification Required")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            Text("We've sent a verification email to:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text(userEmail)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        Text("Please check your email and click the verification link to activate your account.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Button(action: {
                        navigationManager.navigateToRoot()
                    }) {
                        Text("Go to Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                    Spacer()
                }
                .frame(width: AdaptiveLayout.contentWidth(geometry: geometry, horizontalSizeClass: horizontalSizeClass))
                .padding(AdaptiveLayout.formPadding(horizontalSizeClass: horizontalSizeClass))
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AccountSuccessView(userEmail: "manager@example.com")
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}