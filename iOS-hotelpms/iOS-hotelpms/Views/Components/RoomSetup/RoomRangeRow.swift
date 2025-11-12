import SwiftUI

struct RoomRangeRow: View {
    @Binding var range: RoomRange
    let canDelete: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Start Room
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("100", text: $range.startRoom)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(height: 44)
                }
                
                // Arrow
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                    .font(.title2)
                    .padding(.top, 16)
                
                // End Room
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("150", text: $range.endRoom)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(height: 44)
                }
                
                // Delete Button
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 16)
                }
            }
            
            // Range Status
            HStack {
                if range.isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(range.displayText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !range.startRoom.isEmpty || !range.endRoom.isEmpty {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("Check your numbers")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(range.isValid ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}