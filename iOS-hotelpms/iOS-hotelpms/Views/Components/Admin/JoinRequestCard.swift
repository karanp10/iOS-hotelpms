import SwiftUI

struct JoinRequestCard: View {
    let request: JoinRequestMock
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with user info
            HStack(spacing: 12) {
                // Avatar placeholder
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(request.initials)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(request.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status chip
                StatusChip(
                    label: request.status.displayName,
                    color: statusColor(for: request.status)
                )
            }
            
            // Role and date info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Requested Role")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(request.role.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Requested")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(request.requestedDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // Action buttons
            if request.status == .pending {
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Reject")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Button(action: onApprove) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Approve")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func statusColor(for status: JoinRequestStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct StatusChip: View {
    let label: String
    let color: Color
    
    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 16) {
        JoinRequestCard(
            request: MockData.joinRequests[0],
            onApprove: {},
            onReject: {}
        )
        
        JoinRequestCard(
            request: MockData.joinRequests[1],
            onApprove: {},
            onReject: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}