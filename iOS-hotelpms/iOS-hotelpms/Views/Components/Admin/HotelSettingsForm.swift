import SwiftUI

struct HotelSettingsForm: View {
    let hotelId: UUID

    // Basic Information
    @State private var hotelName: String = ""
    @State private var hotelAddress: String = ""
    @State private var hotelPhone: String = ""
    @State private var timezone: String = "Eastern Time (EST)"
    @State private var checkoutTime: Date = Date()

    // Workflow Rules
    @State private var requireMaintenanceNotes: Bool = true
    @State private var requireOOONotes: Bool = true
    @State private var preventCleaningWithDND: Bool = true
    @State private var autoDirtyHours: Int = 2
    @State private var autoStayoverEnabled: Bool = true

    // Flags Configuration
    @State private var enabledFlags: Set<String> = Set()

    // UI State
    @State private var showingSaveToast = false
    @State private var hasChanges = false

    private let timezones = [
        "Pacific Time (PST)",
        "Mountain Time (MST)",
        "Central Time (CST)",
        "Eastern Time (EST)"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Hotel Settings")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if hasChanges {
                    Text("Unsaved Changes")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Settings form
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Information Section
                    SettingsSection(title: "Basic Information") {
                        VStack(spacing: 0) {
                            FormField(
                                label: "Hotel Name",
                                value: $hotelName,
                                placeholder: "Enter hotel name"
                            )

                            Divider()
                                .padding(.leading, 16)

                            FormField(
                                label: "Address",
                                value: $hotelAddress,
                                placeholder: "Enter hotel address"
                            )

                            Divider()
                                .padding(.leading, 16)

                            FormField(
                                label: "Phone",
                                value: $hotelPhone,
                                placeholder: "(555) 123-4567",
                                keyboardType: .phonePad
                            )

                            Divider()
                                .padding(.leading, 16)

                            // Timezone picker
                            HStack {
                                Text("Timezone")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                Picker("", selection: $timezone) {
                                    ForEach(timezones, id: \.self) { tz in
                                        Text(tz).tag(tz)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(16)

                            Divider()
                                .padding(.leading, 16)

                            // Checkout time picker
                            HStack {
                                Text("Default Checkout Time")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                DatePicker("", selection: $checkoutTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            .padding(16)
                        }
                    }

                    // Workflow Rules Section
                    SettingsSection(title: "Workflow Rules") {
                        WorkflowRulesPanel(
                            requireMaintenanceNotes: $requireMaintenanceNotes,
                            requireOOONotes: $requireOOONotes,
                            preventCleaningWithDND: $preventCleaningWithDND,
                            autoDirtyHours: $autoDirtyHours,
                            autoStayoverEnabled: $autoStayoverEnabled
                        )
                    }

                    // Flags Configuration Section
                    SettingsSection(title: "Room Flags") {
                        FlagConfigurationGrid(enabledFlags: $enabledFlags)
                    }

                    // Save button
                    Button(action: saveSettings) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadMockData()
        }
        .onChange(of: hotelName) { _ in hasChanges = true }
        .onChange(of: hotelAddress) { _ in hasChanges = true }
        .onChange(of: hotelPhone) { _ in hasChanges = true }
        .onChange(of: timezone) { _ in hasChanges = true }
        .onChange(of: checkoutTime) { _ in hasChanges = true }
        .onChange(of: requireMaintenanceNotes) { _ in hasChanges = true }
        .onChange(of: requireOOONotes) { _ in hasChanges = true }
        .onChange(of: preventCleaningWithDND) { _ in hasChanges = true }
        .onChange(of: autoDirtyHours) { _ in hasChanges = true }
        .onChange(of: autoStayoverEnabled) { _ in hasChanges = true }
        .onChange(of: enabledFlags) { _ in hasChanges = true }
        .overlay(
            Group {
                if showingSaveToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Settings saved successfully")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .padding()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        )
    }

    private func loadMockData() {
        // Load from MockData
        let settings = MockData.hotelSettings
        hotelName = "Grand Hotel"
        hotelAddress = "123 Main Street, New York, NY 10001"
        hotelPhone = "(555) 123-4567"
        timezone = settings.timezone

        // Set checkout time
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        if let time = formatter.date(from: settings.checkoutTime) {
            checkoutTime = time
        }

        // Workflow rules
        requireMaintenanceNotes = settings.requireMaintenanceNotes
        requireOOONotes = settings.requireOOONotes
        preventCleaningWithDND = settings.preventCleaningWithDND
        autoDirtyHours = settings.autoDirtyHours
        autoStayoverEnabled = settings.autoStayoverEnabled

        // Flags
        enabledFlags = Set(settings.enabledFlags)

        // Reset changes flag after loading
        hasChanges = false
    }

    private func saveSettings() {
        print("Saving hotel settings...")
        print("Hotel: \(hotelName)")
        print("Timezone: \(timezone)")
        print("Checkout: \(checkoutTime)")
        print("Enabled flags: \(enabledFlags)")

        // Show success toast
        withAnimation {
            showingSaveToast = true
            hasChanges = false
        }

        // Hide toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingSaveToast = false
            }
        }
    }
}

struct FormField: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 140, alignment: .leading)

            TextField(placeholder, text: $value)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboardType)
        }
        .padding(16)
    }
}

#Preview("Default") {
    HotelSettingsForm(hotelId: UUID())
}

#Preview("With Changes") {
    struct ChangedPreview: View {
        @State private var settings = HotelSettingsForm(hotelId: UUID())

        var body: some View {
            settings
        }
    }
    return ChangedPreview()
}
