import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            // Section content with rounded background
            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
}

#Preview("Basic Section") {
    VStack(spacing: 20) {
        SettingsSection(title: "Basic Information") {
            VStack(spacing: 0) {
                SettingRow(label: "Hotel Name", value: "Grand Hotel")
                Divider()
                SettingRow(label: "Phone", value: "(555) 123-4567")
                Divider()
                SettingRow(label: "Timezone", value: "Eastern Time")
            }
        }
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Multiple Sections") {
    ScrollView {
        VStack(spacing: 20) {
            SettingsSection(title: "Account") {
                VStack(spacing: 0) {
                    SettingRow(label: "Name", value: "John Doe")
                    Divider()
                    SettingRow(label: "Email", value: "john@hotel.com")
                }
            }

            SettingsSection(title: "Preferences") {
                VStack(spacing: 0) {
                    HStack {
                        Text("Notifications")
                            .font(.body)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    .padding(16)
                }
            }
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

// Helper view for settings rows
struct SettingRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(16)
    }
}
