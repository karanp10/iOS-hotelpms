//
//  HotelInfoView.swift
//  iOS-hotelpms
//
//  Created by Karan Patel on 9/11/25.
//

//
//  HotelInfoView.swift
//  iOS-hotelpms
//
//  Created by Karan Patel on 9/11/25.
//

import SwiftUI

struct HotelInfoView: View {
    let personalData: PersonalData
    @State private var hotelName = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @EnvironmentObject var navigationManager: NavigationManager
    
    @StateObject private var authService = AuthService()
    @StateObject private var databaseService = DatabaseService()
    
    private var isFormValid: Bool {
        return !hotelName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Hotel Information")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Set up your hotel business details")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 20) {
                        // Hotel Basic Info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Information")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Hotel Name", text: $hotelName)
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 44)
                            
                            TextField("Phone Number", text: $phoneNumber)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                                .frame(height: 44)
                        }
                        
                        // Location Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Street Address", text: $address)
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 44)
                            
                            TextField("City", text: $city)
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 44)
                            
                            HStack(spacing: 12) {
                                TextField("State", text: $state)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(height: 44)
                                
                                TextField("ZIP Code", text: $zipCode)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .frame(height: 44)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await createAccountAndHotel()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                }
                                Text(isLoading ? "Creating Account..." : "Create Hotel & Account")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background((isFormValid && !isLoading) ? Color.blue : Color.gray)
                            .cornerRadius(10)
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 40)
                }
                .frame(width: min(400, geometry.size.width * 0.85))
                .padding(.horizontal, 30)
            }
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    @MainActor
    private func createAccountAndHotel() async {
        isLoading = true
        
        do {
            // Step 1: Create user account with Supabase Auth
            let user = try await authService.signUp(
                email: personalData.email,
                password: personalData.password,
                confirmPassword: personalData.password
            )
            
            // Step 2: Create profile record
            let profile = try await databaseService.createProfile(
                firstName: personalData.firstName,
                lastName: personalData.lastName,
                email: personalData.email
            )
            
            // Step 3: Create hotel record
            let hotel = try await databaseService.createHotel(
                name: hotelName.trimmingCharacters(in: .whitespaces),
                address: address.trimmingCharacters(in: .whitespaces).isEmpty ? nil : address.trimmingCharacters(in: .whitespaces),
                city: city.trimmingCharacters(in: .whitespaces).isEmpty ? nil : city.trimmingCharacters(in: .whitespaces),
                state: state.trimmingCharacters(in: .whitespaces).isEmpty ? nil : state.trimmingCharacters(in: .whitespaces),
                zipCode: zipCode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespaces)
            )
            
            // Success! Navigate to success screen
            navigationManager.navigate(to: .accountSuccess(email: personalData.email))
            
        } catch {
            // Handle errors
            alertTitle = "Account Creation Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isLoading = false
    }
}

#Preview {
    HotelInfoView(personalData: PersonalData(
        firstName: "John",
        lastName: "Doe", 
        email: "john@example.com",
        password: "password"
    ))
    .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}
