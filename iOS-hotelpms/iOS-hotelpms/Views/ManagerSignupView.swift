//
//  ManagerSignupView.swift
//  iOS-hotelpms
//
//  Created by Karan Patel on 9/11/25.
//

import SwiftUI

struct ManagerSignupView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var hotelName = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Create Manager Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Set up your hotel and manage your team")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 20) {
                        // Personal Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Personal Information")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
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
                                .frame(height: 44)
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 44)
                        }
                        
                        // Hotel Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Hotel Information")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Hotel Name", text: $hotelName)
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 44)
                        }
                        
                        Button(action: {
                            // Manager signup action will go here
                            print("Create Manager Account tapped")
                            print("Name: \(firstName) \(lastName)")
                            print("Email: \(email)")
                            print("Hotel: \(hotelName)")
                        }) {
                            Text("Create Account & Hotel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 40)
                }
                .frame(width: min(400, geometry.size.width * 0.85))
                .padding(.horizontal, 30)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ManagerSignupView()
}