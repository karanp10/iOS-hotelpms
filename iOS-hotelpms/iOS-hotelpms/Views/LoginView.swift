//
//  LoginView.swift
//  
//
//  Created by Karan Patel on 9/9/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var navigationManager: NavigationManager
    
    @StateObject private var authService = AuthService()
    @StateObject private var databaseService = DatabaseService()
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("Hotel PMS")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sign in to continue")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 20) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .frame(height: 44)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .frame(height: 44)
                    }
                    
                    Button(action: {
                        Task {
                            await signInAndRoute()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            }
                            Text(isLoading ? "Signing In..." : "Sign In")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isLoading ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Button(action: {
                        navigationManager.navigate(to: .personalInfo)
                    }) {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    
                    Spacer()
                }
                .frame(width: min(400, geometry.size.width * 0.8))
                .padding(40)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert("Sign In Failed", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    @MainActor
    private func signInAndRoute() async {
        isLoading = true
        
        do {
            // Step 1: Sign in with Supabase Auth
            let user = try await authService.signIn(email: email, password: password)
            
            // Step 2: Check user's hotel memberships
            let membershipsCount = try await databaseService.getUserMembershipsCount()
            
            if membershipsCount > 0 {
                // User has memberships - navigate to dashboard (placeholder for now)
                alertMessage = "Welcome back! You have \(membershipsCount) hotel membership(s)."
                showingAlert = true
                // TODO: Navigate to actual dashboard
            } else {
                // New user - navigate to account selection
                navigationManager.navigate(to: .accountSelection)
            }
            
        } catch {
            // Handle signin errors
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isLoading = false
    }
}

#Preview {
    LoginView()
}