import SwiftUI

struct JoinRequestCard: View {
    let request: JoinRequestWithProfile
    let isProcessing: Bool
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
                    Text(request.fullName)
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
            
            // Request date info
            VStack(alignment: .leading, spacing: 4) {
                Text("Requested")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let createdAt = request.createdAt {
                    Text(formatDate(createdAt))
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("Unknown")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
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
                    .disabled(isProcessing)

                    Button(action: onApprove) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                            }
                            Text("Approve")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
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
        case .accepted:
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
    let sampleProfile = Profile(
        id: UUID(),
        firstName: "Sarah",
        lastName: "Johnson",
        email: "sarah.johnson@email.com",
        createdAt: Date()
    )

    let sampleRequest = JoinRequestWithProfile(
        id: UUID(),
        profileId: sampleProfile.id,
        hotelId: UUID(),
        status: .pending,
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
        profile: sampleProfile
    )

    VStack(spacing: 16) {
        JoinRequestCard(
            request: sampleRequest,
            isProcessing: false,
            onApprove: { print("Approved") },
            onReject: { print("Rejected") }
        )

        JoinRequestCard(
            request: sampleRequest,
            isProcessing: true,
            onApprove: { print("Approved") },
            onReject: { print("Rejected") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}