import SwiftUI

struct FlagConfigurationGrid: View {
    @Binding var enabledFlags: Set<String>

    private let flags: [(name: String, icon: String, color: Color)] = [
        ("VIP", "star.fill", .yellow),
        ("Rush", "bolt.fill", .orange),
        ("Lockout", "lock.fill", .red),
        ("DND", "hand.raised.fill", .purple),
        ("Maintenance", "wrench.and.screwdriver.fill", .blue),
        ("OOO", "exclamationmark.triangle.fill", .red),
        ("OOS", "xmark.octagon.fill", .gray)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(flags.enumerated()), id: \.offset) { index, flag in
                FlagToggleRow(
                    name: flag.name,
                    icon: flag.icon,
                    color: flag.color,
                    isEnabled: enabledFlags.contains(flag.name),
                    onToggle: { isEnabled in
                        if isEnabled {
                            enabledFlags.insert(flag.name)
                        } else {
                            enabledFlags.remove(flag.name)
                        }
                    }
                )

                if index < flags.count - 1 {
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
    }
}

struct FlagToggleRow: View {
    let name: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(flagDescription(for: name))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
        .padding(16)
    }

    private func flagDescription(for flagName: String) -> String {
        switch flagName {
        case "VIP":
            return "Mark rooms for VIP guests requiring special attention"
        case "Rush":
            return "Priority cleaning needed for urgent turnovers"
        case "Lockout":
            return "Room access restricted due to security concerns"
        case "DND":
            return "Do Not Disturb - guest privacy, no cleaning"
        case "Maintenance":
            return "Room requires maintenance or repairs"
        case "OOO":
            return "Out of Order - room unavailable for guests"
        case "OOS":
            return "Out of Service - room removed from inventory"
        default:
            return "Room flag configuration"
        }
    }
}

#Preview("All Enabled") {
    SettingsSection(title: "Room Flags") {
        FlagConfigurationGrid(
            enabledFlags: .constant(Set(["VIP", "Rush", "Lockout", "DND", "Maintenance", "OOO", "OOS"]))
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Some Disabled") {
    SettingsSection(title: "Room Flags") {
        FlagConfigurationGrid(
            enabledFlags: .constant(Set(["VIP", "Rush", "DND", "Maintenance"]))
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("All Disabled") {
    SettingsSection(title: "Room Flags") {
        FlagConfigurationGrid(
            enabledFlags: .constant(Set())
        )
    }
    .background(Color(.systemGroupedBackground))
}
