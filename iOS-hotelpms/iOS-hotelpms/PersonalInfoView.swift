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
    @EnvironmentObject var navigationManager: NavigationManager
    
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
                            .frame(height: 44)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .frame(height: 44)
                    }
                    
                    Button(action: {
                        let personalData = PersonalData(
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            password: password
                        )
                        navigationManager.navigate(to: .hotelInfo(personalData: personalData))
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
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
    PersonalInfoView()
}