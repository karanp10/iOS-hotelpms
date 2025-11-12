import SwiftUI

struct AlertBanner: View {
    let title: String
    let message: String
    let isPresented: Binding<Bool>
    let primaryAction: (() -> Void)?
    let secondaryAction: (() -> Void)?
    
    init(
        title: String,
        message: String,
        isPresented: Binding<Bool>,
        primaryAction: (() -> Void)? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.isPresented = isPresented
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        VStack {
            EmptyView()
        }
        .alert(title, isPresented: isPresented) {
            if let primaryAction = primaryAction {
                Button("Retry", action: primaryAction)
            }
            if let secondaryAction = secondaryAction {
                Button("Cancel", role: .cancel, action: secondaryAction)
            } else {
                Button("OK") { }
            }
        } message: {
            Text(message)
        }
    }
}