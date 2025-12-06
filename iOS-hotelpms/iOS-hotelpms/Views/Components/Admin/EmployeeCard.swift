import SwiftUI

struct EmployeeCard: View {
    let employee: HotelEmployee
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
                    Text(employee.fullName)
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
        employee: .preview(role: .manager, firstName: "Alex", lastName: "Thompson"),
        isSelected: false,
        onTap: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Different Roles") {
    VStack(spacing: 12) {
        ForEach([
            HotelEmployee.preview(role: .admin, firstName: "Lisa", lastName: "Park"),
            HotelEmployee.preview(role: .manager, firstName: "Jordan", lastName: "Smith"),
            HotelEmployee.preview(role: .frontDesk, firstName: "Taylor", lastName: "Wilson"),
            HotelEmployee.preview(role: .housekeeping, firstName: "Maria", lastName: "Garcia"),
            HotelEmployee.preview(role: .maintenance, firstName: "Robert", lastName: "Davis")
        ]) { employee in
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
            employee: .preview(role: .manager, firstName: "Alex", lastName: "Thompson"),
            isSelected: true,
            onTap: {}
        )

        EmployeeCard(
            employee: .preview(role: .admin, firstName: "Lisa", lastName: "Park"),
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#if DEBUG
extension HotelEmployee {
    static func preview(
        role: HotelRole,
        firstName: String,
        lastName: String,
        email: String? = nil
    ) -> HotelEmployee {
        HotelEmployee(
            id: UUID(),
            profileId: UUID(),
            hotelId: UUID(),
            role: role,
            status: .approved,
            createdAt: Date(),
            profile: Profile(
                id: UUID(),
                firstName: firstName,
                lastName: lastName,
                email: email ?? "\(firstName.lowercased()).\(lastName.lowercased())@hotel.com",
                createdAt: Date()
            )
        )
    }
}
#endif
