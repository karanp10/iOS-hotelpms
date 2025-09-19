import Foundation
import Auth
import PostgREST
import Supabase


class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://hrlbtgpndjrnzvkaobmw.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhybGJ0Z3BuZGpybnp2a2FvYm13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc4NjMxOTgsImV4cCI6MjA2MzQzOTE5OH0.zGyhJ9P0ZPI-5eTAWzyizcz4v4V7jvUegee_k16LUYQ"
        )
    }
    
    // Auth helper methods
    var auth: AuthClient {
        return client.auth
    }
    
    // Database helper methods
    var database: PostgrestClient {
        return client.database
    }
}
