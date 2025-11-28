import SwiftUI

struct EmployeeDetailPanel: View {
    let employee: EmployeeMock
    @State private var showingRoleSheet = false
    @State private var showingRemoveAlert = false
    @State private var selectedRole: HotelRole

    init(employee: EmployeeMock) {
        self.employee = employee
        _selectedRole = State(initialValue: employee.role)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Large avatar
                Circle()
                    .fill(roleColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(employee.initials)
                            .font(.system(size: 36))
                            .fontWeight(.bold)
                            .foregroundColor(roleColor)
                    )
                    .padding(.top, 20)

                // Employee info
                VStack(spacing: 8) {
                    Text(employee.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(employee.email)
                        .font(.body)
                        .foregroundColor(.secondary)

                    // Role chip
                    StatusChip(
                        label: employee.role.displayName,
                        color: roleColor
                    )
                    .padding(.top, 8)
                }

                Divider()
                    .padding(.horizontal)

                // Details section
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(
                        label: "Joined",
                        value: formatDate(employee.joinedDate)
                    )

                    DetailRow(
                        label: "Status",
                        value: employee.isActive ? "Active" : "Inactive"
                    )

                    DetailRow(
                        label: "Role",
                        value: employee.role.displayName
                    )
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingRoleSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.key")
                            Text("Change Role")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        showingRemoveAlert = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.minus")
                            Text("Remove from Hotel")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .sheet(isPresented: $showingRoleSheet) {
            RoleSelectionSheet(
                selectedRole: $selectedRole,
                employeeName: employee.name,
                onSave: {
                    print("Role changed to: \(selectedRole.displayName)")
                    showingRoleSheet = false
                },
                onCancel: {
                    selectedRole = employee.role
                    showingRoleSheet = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        .alert("Remove Employee", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                print("Removed employee: \(employee.name)")
            }
        } message: {
            Text("Are you sure you want to remove \(employee.name) from this hotel? This action cannot be undone.")
        }
    }

    private var roleColor: Color {
        switch employee.role {
        case .admin:
            return .purple
        case .manager:
            return .blue
        case .frontDesk:
            return .green
        case .housekeeping:
            return .orange
        case .maintenance:
            return .red
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview("Manager") {
    EmployeeDetailPanel(employee: MockData.employees[0])
}

#Preview("Front Desk") {
    EmployeeDetailPanel(employee: MockData.employees[2])
}

#Preview("Housekeeping") {
    EmployeeDetailPanel(employee: MockData.employees[4])
}
