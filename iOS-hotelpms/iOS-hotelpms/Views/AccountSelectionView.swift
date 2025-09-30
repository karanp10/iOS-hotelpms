//
//  AccountSelectionView.swift
//  iOS-hotelpms
//
//  Created by Karan Patel on 9/11/25.
//

import SwiftUI

struct AccountSelectionView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                
                VStack(spacing: AdaptiveLayout.verticalSpacing(horizontalSizeClass: horizontalSizeClass)) {
                    Spacer()
                        .frame(minHeight: AdaptiveLayout.topPadding(horizontalSizeClass: horizontalSizeClass))
                    
                    VStack(spacing: 16) {
                        Text("Hotel PMS")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("How would you like to get started?")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if horizontalSizeClass == .regular {
                        // iPad: Side-by-side layout
                        HStack(spacing: 24) {
                            accountOptionButton(
                                icon: "building.2",
                                title: "Create Hotel",
                                description: "Set up a new hotel business and become the manager",
                                color: .blue,
                                action: { navigationManager.navigate(to: .managerHotelSetup) }
                            )
                            
                            accountOptionButton(
                                icon: "person.badge.key",
                                title: "Join as Employee",
                                description: "Request to join an existing hotel",
                                color: .green,
                                action: { navigationManager.navigate(to: .employeeJoin) }
                            )
                        }
                    } else {
                        // iPhone: Vertical layout
                        VStack(spacing: AdaptiveLayout.sectionSpacing(horizontalSizeClass: horizontalSizeClass)) {
                            accountOptionButton(
                                icon: "building.2",
                                title: "Create Hotel",
                                description: "Set up a new hotel business and become the manager",
                                color: .blue,
                                action: { navigationManager.navigate(to: .managerHotelSetup) }
                            )
                            
                            accountOptionButton(
                                icon: "person.badge.key",
                                title: "Join as Employee",
                                description: "Request to join an existing hotel",
                                color: .green,
                                action: { navigationManager.navigate(to: .employeeJoin) }
                            )
                        }
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
    
    private func accountOptionButton(icon: String, title: String, description: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, horizontalSizeClass == .regular ? 32 : 24)
            .padding(.horizontal, 20)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
}

#Preview {
    AccountSelectionView()
}