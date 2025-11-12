import Foundation

// MARK: - Notes Requests

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

// MARK: - Notes Service Errors

enum NotesServiceError: LocalizedError {
    case emptyNoteBody
    case noteNotFound
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyNoteBody:
            return "Note body cannot be empty"
        case .noteNotFound:
            return "Note not found"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}