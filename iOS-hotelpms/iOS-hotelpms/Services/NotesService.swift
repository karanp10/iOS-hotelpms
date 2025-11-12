import Foundation
import Supabase

/// Service responsible for note CRUD operations.
/// Audit logging is handled separately by RoomHistoryService in ViewModels.
class NotesService {
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient? = nil) {
        self.supabaseClient = supabaseClient ?? SupabaseManager.shared.client
    }
    
    // MARK: - Note Creation
    
    func createNote(roomId: UUID, authorId: UUID, body: String) async throws {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NotesServiceError.emptyNoteBody
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
            throw NotesServiceError.networkError("Failed to create note: \(error.localizedDescription)")
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
            throw NotesServiceError.networkError("Failed to get notes: \(error.localizedDescription)")
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
            throw NotesServiceError.networkError("Failed to get all notes: \(error.localizedDescription)")
        }
    }
    
    func getRecentNotesForHotel(hotelId: UUID) async throws -> [RoomNote] {
        let twoDaysAgo = Calendar.current.date(byAdding: .hour, value: -48, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        let twoDaysAgoString = formatter.string(from: twoDaysAgo)
        
        do {
            // Simple approach: get all recent notes first, then filter by hotel
            let response: [RoomNote] = try await supabaseClient
                .from("room_notes")
                .select()
                .gte("created_at", value: twoDaysAgoString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw NotesServiceError.networkError("Failed to get recent notes: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Note Updates
    
    func updateNote(noteId: UUID, body: String) async throws -> RoomNote {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NotesServiceError.emptyNoteBody
        }
        
        // Get the existing note for return value
        let oldNoteResponse: [RoomNote] = try await supabaseClient
            .from("room_notes")
            .select()
            .eq("id", value: noteId)
            .execute()
            .value
        
        guard let oldNote = oldNoteResponse.first else {
            throw NotesServiceError.noteNotFound
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
            
            // Return updated note for audit logging by caller
            return RoomNote(
                id: oldNote.id,
                roomId: oldNote.roomId,
                authorId: oldNote.authorId,
                note: body.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: oldNote.createdAt,
                deletedAt: oldNote.deletedAt
            )
        } catch {
            throw NotesServiceError.networkError("Failed to update note: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Note Deletion
    
    func deleteNote(noteId: UUID) async throws -> RoomNote {
        // Get the note before deletion for audit logging by caller
        let noteResponse: [RoomNote] = try await supabaseClient
            .from("room_notes")
            .select()
            .eq("id", value: noteId)
            .execute()
            .value
        
        guard let note = noteResponse.first else {
            throw NotesServiceError.noteNotFound
        }
        
        do {
            let _ = try await supabaseClient
                .from("room_notes")
                .delete()
                .eq("id", value: noteId)
                .execute()
            
            // Return deleted note for audit logging by caller
            return note
        } catch {
            throw NotesServiceError.networkError("Failed to delete note: \(error.localizedDescription)")
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
            throw NotesServiceError.networkError("Failed to search notes: \(error.localizedDescription)")
        }
    }
}
