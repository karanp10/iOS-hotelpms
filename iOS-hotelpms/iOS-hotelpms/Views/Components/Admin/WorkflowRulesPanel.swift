import SwiftUI

struct WorkflowRulesPanel: View {
    @Binding var requireMaintenanceNotes: Bool
    @Binding var requireOOONotes: Bool
    @Binding var preventCleaningWithDND: Bool
    @Binding var autoDirtyHours: Int
    @Binding var autoStayoverEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Auto-dirty after checkout
            WorkflowRuleRow(
                icon: "clock.badge.checkmark",
                title: "Auto-dirty after checkout",
                description: "Automatically mark rooms as dirty after checkout",
                isOn: .constant(true)
            )
            .disabled(true) // Always on for this rule

            Divider()
                .padding(.leading, 60)

            // Auto-dirty delay hours
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "hourglass")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-dirty delay")
                            .font(.body)
                            .foregroundColor(.primary)

                        Text("Hours after checkout before auto-dirty")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Picker("", selection: $autoDirtyHours) {
                        ForEach(1..<13) { hours in
                            Text("\(hours)h").tag(hours)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }
                .padding(16)
            }

            Divider()
                .padding(.leading, 60)

            // Auto-stayover at midnight
            WorkflowRuleRow(
                icon: "moon.stars",
                title: "Auto-stayover at midnight",
                description: "Automatically mark occupied rooms as stayover at midnight",
                isOn: $autoStayoverEnabled
            )

            Divider()
                .padding(.leading, 60)

            // Require maintenance notes
            WorkflowRuleRow(
                icon: "wrench.and.screwdriver",
                title: "Require maintenance notes",
                description: "Require notes when marking room for maintenance",
                isOn: $requireMaintenanceNotes
            )

            Divider()
                .padding(.leading, 60)

            // Require OOO notes
            WorkflowRuleRow(
                icon: "exclamationmark.triangle",
                title: "Require Out of Order notes",
                description: "Require notes when marking room as Out of Order",
                isOn: $requireOOONotes
            )

            Divider()
                .padding(.leading, 60)

            // Prevent cleaning with DND
            WorkflowRuleRow(
                icon: "hand.raised",
                title: "Prevent cleaning with DND",
                description: "Block cleaning status changes when Do Not Disturb is active",
                isOn: $preventCleaningWithDND
            )
        }
    }
}

struct WorkflowRuleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(16)
    }
}

#Preview("All Enabled") {
    SettingsSection(title: "Workflow Rules") {
        WorkflowRulesPanel(
            requireMaintenanceNotes: .constant(true),
            requireOOONotes: .constant(true),
            preventCleaningWithDND: .constant(true),
            autoDirtyHours: .constant(2),
            autoStayoverEnabled: .constant(true)
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("All Disabled") {
    SettingsSection(title: "Workflow Rules") {
        WorkflowRulesPanel(
            requireMaintenanceNotes: .constant(false),
            requireOOONotes: .constant(false),
            preventCleaningWithDND: .constant(false),
            autoDirtyHours: .constant(2),
            autoStayoverEnabled: .constant(false)
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Mixed State") {
    SettingsSection(title: "Workflow Rules") {
        WorkflowRulesPanel(
            requireMaintenanceNotes: .constant(true),
            requireOOONotes: .constant(false),
            preventCleaningWithDND: .constant(true),
            autoDirtyHours: .constant(4),
            autoStayoverEnabled: .constant(false)
        )
    }
    .background(Color(.systemGroupedBackground))
}
