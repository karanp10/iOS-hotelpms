//
//  AccountSelectionView.swift
//  iOS-hotelpms
//
//  Created by Karan Patel on 9/11/25.
//

import SwiftUI

struct AccountSelectionView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
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
                        
                        Text("How would you like to get started?")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            navigationManager.navigate(to: .managerHotelSetup)
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                                
                                Text("Create Hotel")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Set up a new hotel business and become the manager")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 20)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            navigationManager.navigate(to: .employeeJoin)
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "person.badge.key")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                                
                                Text("Join as Employee")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Request to join an existing hotel")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 20)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
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
    AccountSelectionView()
}