import SwiftUI

struct RoleSelectionSheet: View {
    @Binding var selectedRole: HotelRole
    let employeeName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Employee info
                VStack(spacing: 8) {
                    Text("Change Role")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(employeeName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Role picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Role")
                        .font(.headline)
                        .padding(.horizontal, 16)

                    ForEach(HotelRole.allCases, id: \.self) { role in
                        Button(action: {
                            selectedRole = role
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(role.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    Text(roleDescription(for: role))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedRole == role {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(16)
                            .background(selectedRole == role ? Color.blue.opacity(0.1) : Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onSave) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func roleDescription(for role: HotelRole) -> String {
        switch role {
        case .admin:
            return "Full system access and control"
        case .manager:
            return "Manage staff and hotel operations"
        case .frontDesk:
            return "Handle guest check-ins and reservations"
        case .housekeeping:
            return "Manage room cleaning and maintenance"
        case .maintenance:
            return "Handle repairs and facilities"
        }
    }
}

#Preview("Manager Selected") {
    RoleSelectionSheet(
        selectedRole: .constant(.manager),
        employeeName: "Alex Thompson",
        onSave: {},
        onCancel: {}
    )
}

#Preview("Front Desk Selected") {
    RoleSelectionSheet(
        selectedRole: .constant(.frontDesk),
        employeeName: "Jordan Smith",
        onSave: {},
        onCancel: {}
    )
}
