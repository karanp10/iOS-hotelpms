import SwiftUI

struct JoinRequestsList: View {
    let hotelId: UUID
    @StateObject private var viewModel: JoinRequestsViewModel

    init(hotelId: UUID) {
        self.hotelId = hotelId
        self._viewModel = StateObject(wrappedValue: JoinRequestsViewModel(hotelId: hotelId))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with stats
            JoinRequestsHeader(pendingCount: viewModel.pendingCount)

            if viewModel.isLoading {
                // Loading state
                VStack {
                    ProgressView("Loading join requests...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.joinRequests.isEmpty {
                // Empty state
                JoinRequestsEmptyState()
            } else {
                // Request list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.joinRequests) { request in
                            JoinRequestCard(
                                request: request,
                                isProcessing: viewModel.isProcessing(request.id),
                                onApprove: {
                                    viewModel.startApproval(requestId: request.id)
                                },
                                onReject: {
                                    Task {
                                        await viewModel.rejectRequest(requestId: request.id)
                                    }
                                }
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
        .sheet(isPresented: $viewModel.showingRolePicker) {
            RolePickerSheet(
                selectedRole: $viewModel.selectedRole,
                onConfirm: {
                    Task {
                        await viewModel.confirmApproval()
                    }
                },
                onCancel: {
                    viewModel.cancelApproval()
                }
            )
            .presentationDetents([.medium])
        }
        .overlay(alignment: .bottom) {
            if viewModel.showingToast {
                ToastView(message: viewModel.toastMessage)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showingToast)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 70)
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                viewModel.retryLoad()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.loadJoinRequests()
        }
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
                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
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

#Preview("Empty") {
    JoinRequestsList(hotelId: UUID())
}
