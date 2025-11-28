import SwiftUI

struct ProfileCard: View {
    // Mock user data
    private let mockUser = MockData.currentUser
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(mockUser.initials)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mockUser.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(mockUser.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(mockUser.role.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ProfileCard()
        .padding()
}