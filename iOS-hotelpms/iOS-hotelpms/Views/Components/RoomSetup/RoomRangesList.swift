import SwiftUI

struct RoomRangesList: View {
    @ObservedObject var viewModel: RoomSetupViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Room Ranges")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(Array(viewModel.roomRanges.enumerated()), id: \.element.id) { index, range in
                RoomRangeRow(
                    range: Binding(
                        get: { viewModel.roomRanges[index] },
                        set: { viewModel.updateRange(at: index, with: $0) }
                    ),
                    canDelete: viewModel.canDeleteRange,
                    onDelete: {
                        viewModel.removeRange(at: index)
                    }
                )
            }
            
            // Add Range Button
            Button(action: {
                viewModel.addRange()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Range")
                        .font(.headline)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}