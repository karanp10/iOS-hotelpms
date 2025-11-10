import SwiftUI

struct ToastStack: View {
    let showingToast: Bool
    let toastMessage: String
    let showingUndo: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if showingToast {
                ToastView(message: toastMessage)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(.easeInOut(duration: 0.3), value: showingToast)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, showingUndo ? 120 : 70)
    }
}

struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack {
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        ToastStack(
            showingToast: true,
            toastMessage: "Room 101 marked as Occupied ✅",
            showingUndo: false
        )
    }
}