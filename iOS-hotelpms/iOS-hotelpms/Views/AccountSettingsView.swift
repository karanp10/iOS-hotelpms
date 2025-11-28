import SwiftUI

struct AccountSettingsView: View {
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    ProfileCard()
                }
                
                // Preferences Section
                Section("Preferences") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                }
                
                // Account Section
                Section("Account") {
                    NavigationLink(destination: MembershipsListView()) {
                        Label("Hotels", systemImage: "building.2")
                    }
                    
                    Button(role: .destructive) {
                        // TODO: Implement logout
                    } label: {
                        Label("Sign Out", systemImage: "door.right.hand.open")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Account")
            .listStyle(InsetGroupedListStyle())
            
            // Detail view placeholder for iPad split view
            Text("Select an option")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(.automatic) // Use automatic navigation view style
    }
}

// MARK: - Placeholder Views (will be implemented later)

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Text("Appearance Settings")
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct MembershipsListView: View {
    var body: some View {
        Text("Hotel Memberships")
            .navigationTitle("Hotels")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AccountSettingsView()
}