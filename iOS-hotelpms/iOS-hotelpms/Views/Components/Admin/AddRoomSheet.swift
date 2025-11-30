import SwiftUI

struct AddRoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Int, Int) -> Void

    @State private var roomNumber: String = ""
    @State private var floorNumber: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Room Details")) {
                    HStack {
                        Text("Room Number")
                            .frame(width: 120, alignment: .leading)
                        TextField("e.g., 101", text: $roomNumber)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Floor Number")
                            .frame(width: 120, alignment: .leading)
                        TextField("e.g., 1", text: $floorNumber)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    // Validation info
                    if !isFormValid {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Please fill in all required fields")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoom()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isFormValid: Bool {
        guard !roomNumber.isEmpty,
              !floorNumber.isEmpty,
              let _ = Int(roomNumber),
              let _ = Int(floorNumber) else {
            return false
        }
        return true
    }

    private func saveRoom() {
        guard let roomNum = Int(roomNumber),
              let floorNum = Int(floorNumber) else {
            errorMessage = "Please enter valid numbers"
            showingError = true
            return
        }

        // Validate room number is positive
        guard roomNum > 0, floorNum > 0 else {
            errorMessage = "Room and floor numbers must be positive"
            showingError = true
            return
        }

        onSave(roomNum, floorNum)
        dismiss()
    }
}

#Preview("Empty Form") {
    AddRoomSheet { roomNum, floorNum in
        print("Added room \(roomNum) on floor \(floorNum)")
    }
}

#Preview("Partially Filled") {
    struct PartialPreview: View {
        var body: some View {
            AddRoomSheet { _, _ in }
        }
    }
    return PartialPreview()
}

#Preview("Completely Filled") {
    struct FilledPreview: View {
        var body: some View {
            AddRoomSheet { _, _ in }
        }
    }
    return FilledPreview()
}
