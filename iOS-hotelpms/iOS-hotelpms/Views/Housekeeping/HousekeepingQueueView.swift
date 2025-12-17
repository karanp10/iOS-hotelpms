import SwiftUI

struct HousekeepingQueueView: View {
    @StateObject private var viewModel: HousekeepingQueueViewModel
    @State private var noteTargetRoom: Room?
    @State private var noteText: String = ""
    @State private var isSavingNote = false
    @State private var noteError: String?

    private let gridColumns = [
        GridItem(.adaptive(minimum: 380), spacing: 18)
    ]

    init(hotelId: UUID) {
        _viewModel = StateObject(wrappedValue: HousekeepingQueueViewModel(hotelId: hotelId))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with counts
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cleaning Queue")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(viewModel.queueCount) waiting • \(viewModel.inProgressCount) in progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))

                Divider()

                content
            }
            .background(Color(.systemGroupedBackground))

            // Toast overlay
            VStack {
                Spacer()
                ToastStack(
                    showingToast: viewModel.showingToast,
                    toastMessage: viewModel.toastMessage,
                    showingUndo: false
                )
            }
        }
        .task {
            await viewModel.loadQueue()
        }
        .sheet(item: $noteTargetRoom) { room in
            NavigationView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Room \(room.displayNumber)")
                        .font(.headline)

                    notesList

                    TextEditor(text: $noteText)
                        .frame(minHeight: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2))
                        )

                    if let noteError = noteError ?? viewModel.notesError {
                        Text(noteError)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }

                    Button {
                        saveNote(for: room)
                    } label: {
                        HStack {
                            if isSavingNote {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                            Text("Save Note")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSavingNote)

                    Spacer()
                }
                .padding()
                .navigationTitle("Notes")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            resetNoteComposer()
                        }
                    }
                }
                .task {
                    await viewModel.loadNotesForRoom(roomId: room.id)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView("Loading queue...")
            Spacer()
        } else if let error = viewModel.error {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Try Again") {
                    Task {
                        await viewModel.loadQueue()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        } else if viewModel.isQueueEmpty {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("All caught up!")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("No rooms in the cleaning queue")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            Spacer()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !viewModel.availableFloors.isEmpty {
                        floorFilter
                    }

                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(viewModel.displayedRooms) { room in
                            CleaningRoomCard(
                                room: room,
                                onStartCleaning: room.canStartCleaning() ? {
                                    Task {
                                        await viewModel.startCleaning(roomId: room.id)
                                    }
                                } : nil,
                                onMarkReady: room.canMarkReady() ? {
                                    Task {
                                        await viewModel.markReady(roomId: room.id)
                                    }
                                } : nil,
                                onUndo: {
                                    viewModel.executeUndo(roomId: room.id)
                                },
                                isInUndoMode: viewModel.roomsInUndoMode.contains(room.id),
                                onAddNote: {
                                    noteTargetRoom = room
                                    noteText = ""
                                    noteError = nil
                                    Task {
                                        await viewModel.loadNotesForRoom(roomId: room.id)
                                    }
                                },
                                noteCount: viewModel.noteCounts[room.id]
                            )
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private var floorFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                floorChip(label: "All", isSelected: viewModel.selectedFloor == nil) {
                    viewModel.selectedFloor = nil
                }

                ForEach(viewModel.availableFloors, id: \.self) { floor in
                    floorChip(label: "Floor \(floor)", isSelected: viewModel.selectedFloor == floor) {
                        viewModel.selectedFloor = floor
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func floorChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                )
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes

    private func saveNote(for room: Room) {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            noteError = "Note cannot be empty."
            return
        }

        isSavingNote = true
        noteError = nil

        Task {
            let success = await viewModel.addNote(roomId: room.id, body: trimmed)

            await MainActor.run {
                isSavingNote = false
                if success {
                    noteText = ""
                    resetNoteComposer()
                } else if let viewError = viewModel.error {
                    noteError = viewError
                }
            }
        }
    }

    private func resetNoteComposer() {
        noteText = ""
        noteError = nil
        noteTargetRoom = nil
    }

    // MARK: - Notes List

    @ViewBuilder
    private var notesList: some View {
        if viewModel.isLoadingNotes {
            HStack {
                ProgressView()
                Text("Loading notes...")
                    .foregroundColor(.secondary)
            }
        } else if let notesError = viewModel.notesError {
            VStack(alignment: .leading, spacing: 8) {
                Text(notesError)
                    .font(.subheadline)
                    .foregroundColor(.red)
                Button("Retry") {
                    if let room = noteTargetRoom {
                        Task { await viewModel.loadNotesForRoom(roomId: room.id) }
                    }
                }
                .buttonStyle(.bordered)
            }
        } else if viewModel.activeNotes.isEmpty {
            Text("No notes yet.")
                .foregroundColor(.secondary)
                .font(.subheadline)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.activeNotes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.note)
                            .font(.body)
                        if let createdAt = note.createdAt {
                            Text(relativeTime(for: createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
            }
        }
    }

    private func relativeTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    HousekeepingQueueView(hotelId: UUID())
}
