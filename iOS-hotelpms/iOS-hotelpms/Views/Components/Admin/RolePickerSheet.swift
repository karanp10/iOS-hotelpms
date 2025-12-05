import SwiftUI

struct RolePickerSheet: View {
    @Binding var selectedRole: HotelRole
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assign Role")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Select the role for this employee")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.systemBackground))

                Divider()

                // Role options
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(HotelRole.allCases, id: \.self) { role in
                            RoleOptionCard(
                                role: role,
                                isSelected: selectedRole == role,
                                onSelect: {
                                    selectedRole = role
                                }
                            )
                        }
                    }
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground))

                Divider()

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onConfirm) {
                        Text("Confirm")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(20)
                .background(Color(.systemBackground))
            }
            .navigationBarHidden(true)
        }
    }
}

struct RoleOptionCard: View {
    let role: HotelRole
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Role icon
                Image(systemName: iconForRole(role))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(10)

                // Role info
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(descriptionForRole(role))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func iconForRole(_ role: HotelRole) -> String {
        switch role {
        case .admin:
            return "shield.checkered"
        case .manager:
            return "person.badge.key"
        case .frontDesk:
            return "person.text.rectangle"
        case .housekeeping:
            return "sparkles"
        case .maintenance:
            return "wrench.and.screwdriver"
        }
    }

    private func descriptionForRole(_ role: HotelRole) -> String {
        switch role {
        case .admin:
            return "Full access to all hotel settings and management"
        case .manager:
            return "Manage staff, approve requests, and view reports"
        case .frontDesk:
            return "Handle check-ins, room assignments, and guest services"
        case .housekeeping:
            return "Update room cleaning status and maintenance requests"
        case .maintenance:
            return "Handle maintenance requests and room repairs"
        }
    }
}

#Preview {
    RolePickerSheet(
        selectedRole: .constant(.housekeeping),
        onConfirm: { print("Confirmed") },
        onCancel: { print("Cancelled") }
    )
}
