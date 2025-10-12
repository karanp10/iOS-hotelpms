import Foundation
import Supabase

class NotesService {
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }
    
    // MARK: - Note Creation
    
    func createNote(roomId: UUID, authorId: UUID, body: String) async throws {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DatabaseError.networkError("Note body cannot be empty")
        }
        
        let noteRequest = CreateNoteRequest(
            roomId: roomId,
            authorId: authorId,
            note: body.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        do {
            let _ = try await supabaseClient
                .from("room_notes")
                .insert(noteRequest)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to create note: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Note Retrieval
    
    func getNotesForRoom(roomId: UUID, limit: Int = 50) async throws -> [RoomNote] {
        do {
            let response: [RoomNote] = try await supabaseClient
                .from("room_notes")
                .select()
                .eq("room_id", value: roomId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw DatabaseError.networkError("Failed to get notes: \(error.localizedDescription)")
        }
    }
    
    func getAllNotes(limit: Int = 100) async throws -> [RoomNote] {
        do {
            let response: [RoomNote] = try await supabaseClient
                .from("room_notes")
                .select()
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw DatabaseError.networkError("Failed to get all notes: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Note Updates
    
    func updateNote(noteId: UUID, body: String) async throws {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DatabaseError.networkError("Note body cannot be empty")
        }
        
        let updateRequest = UpdateNoteRequest(
            note: body.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        do {
            let _ = try await supabaseClient
                .from("room_notes")
                .update(updateRequest)
                .eq("id", value: noteId)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to update note: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Note Deletion
    
    func deleteNote(noteId: UUID) async throws {
        do {
            let _ = try await supabaseClient
                .from("room_notes")
                .delete()
                .eq("id", value: noteId)
                .execute()
        } catch {
            throw DatabaseError.networkError("Failed to delete note: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Note Search
    
    func searchNotes(query: String, roomId: UUID? = nil) async throws -> [RoomNote] {
        let searchPattern = "%\(query)%"
        
        do {
            if let roomId = roomId {
                let response: [RoomNote] = try await supabaseClient
                    .from("room_notes")
                    .select()
                    .ilike("note", pattern: searchPattern)
                    .eq("room_id", value: roomId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                return response
            } else {
                let response: [RoomNote] = try await supabaseClient
                    .from("room_notes")
                    .select()
                    .ilike("note", pattern: searchPattern)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                return response
            }
        } catch {
            throw DatabaseError.networkError("Failed to search notes: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

struct CreateNoteRequest: Codable {
    let roomId: UUID
    let authorId: UUID
    let note: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case authorId = "author_id"
        case note
        case createdAt = "created_at"
    }
    
    init(roomId: UUID, authorId: UUID, note: String) {
        self.roomId = roomId
        self.authorId = authorId
        self.note = note
        self.createdAt = Date()
    }
}

struct UpdateNoteRequest: Codable {
    let note: String
    
    enum CodingKeys: String, CodingKey {
        case note
    }
}

struct RoomNote: Codable, Identifiable {
    let id: UUID
    let roomId: UUID
    let authorId: UUID?
    let note: String
    let createdAt: Date?
    let deletedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomId = "room_id"
        case authorId = "author_id" 
        case note
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
    
    var isRecent: Bool {
        guard let createdAt = createdAt else { return false }
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return createdAt > dayAgo
    }
    
    var preview: String {
        note.count > 50 ? String(note.prefix(47)) + "..." : note
    }
    
    var body: String {
        return note // For backward compatibility with UI code
    }
}