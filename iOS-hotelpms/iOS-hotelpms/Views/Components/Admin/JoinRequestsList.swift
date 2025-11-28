import SwiftUI

struct JoinRequestsList: View {
    let hotelId: UUID
    @State private var isLoading = false
    
    // Mock data for now
    private let mockRequests = MockData.joinRequests
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with stats
            JoinRequestsHeader(pendingCount: mockRequests.count)
            
            if isLoading {
                // Loading state
                VStack {
                    ProgressView("Loading join requests...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if mockRequests.isEmpty {
                // Empty state
                JoinRequestsEmptyState()
            } else {
                // Request list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(mockRequests) { request in
                            JoinRequestCard(
                                request: request,
                                onApprove: { approveRequest(request) },
                                onReject: { rejectRequest(request) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // TODO: Load real data
        }
    }
    
    private func approveRequest(_ request: JoinRequestMock) {
        // TODO: Implement approve logic
        print("Approved: \(request.name)")
    }
    
    private func rejectRequest(_ request: JoinRequestMock) {
        // TODO: Implement reject logic
        print("Rejected: \(request.name)")
    }
}

struct JoinRequestsHeader: View {
    let pendingCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Join Requests")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Pending count badge
                Text("\(pendingCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(pendingCount > 0 ? Color.blue : Color.gray)
                    .clipShape(Circle())
            }
            
            Text("Review employee requests to join your hotel")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

struct JoinRequestsEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No pending requests")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("New employee join requests will appear here for approval")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("With Requests") {
    JoinRequestsList(hotelId: UUID())
}

#Preview("Loading") {
    JoinRequestsList(hotelId: UUID())
}

#Preview("Empty") {
    JoinRequestsList(hotelId: UUID())
}