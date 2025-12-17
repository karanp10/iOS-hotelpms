import SwiftUI

struct HousekeepingActivityView: View {
    @StateObject private var viewModel: HousekeepingActivityViewModel

    init(hotelId: UUID) {
        _viewModel = StateObject(wrappedValue: HousekeepingActivityViewModel(hotelId: hotelId))
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Activity Scope", selection: $viewModel.scope) {
                ForEach(HousekeepingActivityViewModel.ActivityScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            content
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.loadActivity()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView("Loading activity...")
            Spacer()
        } else if let error = viewModel.error {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text(error)
                    .foregroundColor(.secondary)
                Button("Retry") {
                    Task { await viewModel.loadActivity() }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        } else {
            let entries = currentEntries
            if entries.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No activity yet")
                        .font(.headline)
                    Text("Recent updates will show here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(entries) { entry in
                        ActivityRow(entry: entry, timeText: relativeTime(for: entry.createdAt))
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
    }

    private var currentEntries: [RoomHistoryEntry] {
        viewModel.scope == .mine ? viewModel.myActivity : viewModel.teamActivity
    }

    private func relativeTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let entry: RoomHistoryEntry
    let timeText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.changeTypeIcon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayChangeDescription)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Text(timeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    HousekeepingActivityView(hotelId: UUID())
}
