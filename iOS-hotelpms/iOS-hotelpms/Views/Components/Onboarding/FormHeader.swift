import SwiftUI

struct FormHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}