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
    @EnvironmentObject var navigationManager: NavigationManager
    
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
                            // Here we would create the account and hotel with Supabase
                            // For now, navigate to success screen
                            navigationManager.navigate(to: .accountSuccess(email: personalData.email))
                        }) {
                            Text("Create Hotel & Account")
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
    HotelInfoView(personalData: PersonalData(
        firstName: "John",
        lastName: "Doe", 
        email: "john@example.com",
        password: "password"
    ))
    .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}
