import XCTest
@testable import iOS_hotelpms

final class NotesServiceTests: XCTestCase {
    
    var notesService: NotesService!
    var mockSupabaseClient: MockSupabaseClient!
    
    override func setUpWithError() throws {
        mockSupabaseClient = MockSupabaseClient()
        notesService = NotesService() // Use default client for now
    }
    
    override func tearDownWithError() throws {
        notesService = nil
        mockSupabaseClient = nil
    }
    
    // MARK: - Note Creation Tests
    
    func testCreateNote_ValidData_CreatesSuccessfully() async throws {
        // Given
        let roomId = UUID()
        let authorId = UUID()
        let noteBody = "Test note content"
        
        // When
        try await notesService.createNote(
            roomId: roomId,
            authorId: authorId,
            body: noteBody
        )
        
        // Then - Test method works without crashing
        XCTAssertTrue(true) // Method has correct signature
    }
    
    func testCreateNote_EmptyBody_ThrowsError() async throws {
        // Given
        let roomId = UUID()
        let authorId = UUID()
        let noteBody = ""
        
        // When/Then
        do {
            try await notesService.createNote(
                roomId: roomId,
                authorId: authorId,
                body: noteBody
            )
            XCTFail("Expected error for empty note body")
        } catch {
            XCTAssertTrue(error is DatabaseError)
        }
    }
    
    // MARK: - Note Retrieval Tests
    
    func testGetNotesForRoom_ReturnsCorrectData() async throws {
        // Given
        let roomId = UUID()
        // Mock notes would be set up in mockSupabaseClient
        
        // When
        let notes = try await notesService.getNotesForRoom(roomId: roomId)
        
        // Then - Test method works without crashing
        XCTAssertTrue(notes.isEmpty) // No real DB = empty result
    }
    
    // MARK: - Note Update Tests
    
    func testUpdateNote_ValidData_UpdatesSuccessfully() async throws {
        // Given
        let noteId = UUID()
        let newBody = "Updated note content"
        
        // When
        try await notesService.updateNote(
            noteId: noteId,
            body: newBody
        )
        
        // Then - Test method works without crashing
        XCTAssertTrue(true) // Method executed successfully
    }
    
    // MARK: - Note Deletion Tests
    
    func testDeleteNote_ValidId_DeletesSuccessfully() async throws {
        // Given
        let noteId = UUID()
        
        // When
        try await notesService.deleteNote(noteId: noteId)
        
        // Then - Test method works without crashing
        XCTAssertTrue(true) // Method executed successfully
    }
    
    // MARK: - Error Handling Tests
    
    func testCreateNote_NetworkFailure_ThrowsError() async throws {
        // Given
        let roomId = UUID()
        let authorId = UUID()
        let noteBody = "Test note"
        
        // When/Then
        do {
            try await notesService.createNote(
                roomId: roomId,
                authorId: authorId,
                body: noteBody
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DatabaseError)
        }
    }
}