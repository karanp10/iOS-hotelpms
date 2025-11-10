import SwiftUI

struct NotesPanel: View {
    let room: Room
    @Binding var roomNotes: String
    let existingNotes: [RoomNote]
    let isLoadingNotes: Bool
    let onSaveNotes: () -> Void
    let formatDate: (Date) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isLoadingNotes {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Existing notes display
            if !existingNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Notes (\(existingNotes.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(existingNotes) { note in
                                NoteRow(note: note, formatDate: formatDate)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
                
                Divider()
            }
            
            // New note input
            VStack(alignment: .leading, spacing: 8) {
                Text("Add New Note")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $roomNotes)
                    .font(.subheadline)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .onAppear {
                        if roomNotes.isEmpty {
                            roomNotes = "Add notes about this room..."
                        }
                    }
                
                // Save button
                HStack {
                    Spacer()
                    
                    Button("Save Notes") {
                        onSaveNotes()
                    }
                    .disabled(isNoteSaveDisabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isNoteSaveDisabled ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var isNoteSaveDisabled: Bool {
        roomNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
        roomNotes == "Add notes about this room..."
    }
}

struct NoteRow: View {
    let note: RoomNote
    let formatDate: (Date) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.note)
                    .font(.subheadline)
                
                Spacer()
                
                Text(formatDate(note.createdAt ?? Date()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if note.isRecent {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    
                    Text("Recent")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

#Preview {
    let sampleRoom = Room(
        id: UUID(),
        hotelId: UUID(),
        roomNumber: 101,
        floorNumber: 1,
        occupancyStatus: .vacant,
        cleaningStatus: .ready,
        flags: [],
        notes: "",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    let sampleNotes = [
        RoomNote(id: UUID(), roomId: UUID(), authorId: nil, note: "Guest requested extra towels", createdAt: Date(), deletedAt: nil)
    ]
    
    NotesPanel(
        room: sampleRoom,
        roomNotes: .constant("Add notes about this room..."),
        existingNotes: sampleNotes,
        isLoadingNotes: false,
        onSaveNotes: {},
        formatDate: { _ in "Today 2:30 PM" }
    )
}