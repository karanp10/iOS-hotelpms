import SwiftUI

struct EmployeeCard: View {
    let employee: EmployeeMock
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar with initials
                Circle()
                    .fill(roleColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(employee.initials)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(roleColor)
                    )

                // Employee info
                VStack(alignment: .leading, spacing: 4) {
                    Text(employee.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(employee.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Role chip
                StatusChip(
                    label: employee.role.displayName,
                    color: roleColor
                )
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
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
}

#Preview("Single Employee") {
    EmployeeCard(
        employee: MockData.employees[0],
        isSelected: false,
        onTap: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Different Roles") {
    VStack(spacing: 12) {
        ForEach(MockData.employees.prefix(5)) { employee in
            EmployeeCard(
                employee: employee,
                isSelected: false,
                onTap: {}
            )
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Selected State") {
    VStack(spacing: 12) {
        EmployeeCard(
            employee: MockData.employees[0],
            isSelected: true,
            onTap: {}
        )

        EmployeeCard(
            employee: MockData.employees[1],
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
