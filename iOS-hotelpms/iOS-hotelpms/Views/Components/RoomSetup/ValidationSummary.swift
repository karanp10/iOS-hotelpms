import SwiftUI

struct ValidationSummary: View {
    @ObservedObject var viewModel: RoomSetupViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Validation Messages
            if viewModel.hasOverlappingRanges {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Room ranges cannot overlap!")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Summary
            if viewModel.totalRoomCount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Total: \(viewModel.totalRoomCount) rooms")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    if viewModel.hasValidRanges {
                        Text("Ranges: \(viewModel.validRangesDisplayText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Create Rooms Button
            Button(action: {
                Task { await viewModel.createRooms() }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }
                    
                    Text(viewModel.isLoading ? "Creating Rooms..." : "Create Rooms")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isFormValid && !viewModel.isLoading ? Color.blue : Color.gray)
                .cornerRadius(10)
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
        }
    }
}