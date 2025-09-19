//
//  PersonalInfoView.swift
//  iOS-hotelpms
//
//  Created by Karan Patel on 9/11/25.
//

import SwiftUI

struct PersonalInfoView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @EnvironmentObject var navigationManager: NavigationManager
    
    @StateObject private var authService = AuthService()
    @StateObject private var databaseService = DatabaseService()
    
    private var isFormValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !email.trimmingCharacters(in: .whitespaces).isEmpty &&
               password.count >= 6 &&
               password == confirmPassword
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Personal Information")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Tell us about yourself")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 44)
                            
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 44)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .frame(height: 44)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                            .frame(height: 44)
                            .textContentType(.none)
                            .autocorrectionDisabled()
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                            .frame(height: 44)
                            .textContentType(.none)
                            .autocorrectionDisabled()
                    }
                    
                    Button(action: {
                        if isFormValid {
                            Task {
                                await createAccount()
                            }
                        } else {
                            validateForm()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            }
                            Text(isLoading ? "Creating Account..." : "Create Account")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background((isFormValid && !isLoading) ? Color.blue : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isLoading)
                }
                .frame(width: min(400, geometry.size.width * 0.8))
                .padding(40)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert("Validation Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    @MainActor
    private func createAccount() async {
        isLoading = true
        
        do {
            // Create account with Supabase Auth - passes firstName/lastName as metadata
            // Profile will be auto-created when user verifies email via database trigger
            let user = try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                password: password,
                confirmPassword: confirmPassword,
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces)
            )
            
            // Navigate to email verification screen
            navigationManager.navigate(to: .emailVerification(email: email.trimmingCharacters(in: .whitespaces).lowercased()))
            
        } catch {
            // Handle signup errors
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isLoading = false
    }
    
    private func validateForm() {
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Please enter your first name"
        } else if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Please enter your last name"
        } else if email.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Please enter your email address"
        } else if password.count < 6 {
            alertMessage = "Password must be at least 6 characters long"
        } else if password != confirmPassword {
            alertMessage = "Passwords do not match"
        }
        showingAlert = true
    }
}

#Preview {
    PersonalInfoView()
}
