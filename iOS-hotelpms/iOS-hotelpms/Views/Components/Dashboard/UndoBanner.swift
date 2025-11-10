import SwiftUI

struct UndoBanner: View {
    let showingUndo: Bool
    let undoMessage: String
    let onUndo: () -> Void
    
    var body: some View {
        VStack {
            if showingUndo {
                HStack {
                    Text(undoMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Undo") {
                        onUndo()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.9))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 50)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            UndoBanner(
                showingUndo: true,
                undoMessage: "Changed occupancy to Occupied",
                onUndo: {}
            )
        }
    }
}