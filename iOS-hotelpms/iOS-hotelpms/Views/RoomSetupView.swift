import SwiftUI

struct RoomRange {
    var id = UUID()
    var startRoom: String = ""
    var endRoom: String = ""
    
    var isValid: Bool {
        guard let start = Int(startRoom), let end = Int(endRoom) else { return false }
        return start > 0 && end > 0 && start <= end
    }
    
    var roomCount: Int {
        guard let start = Int(startRoom), let end = Int(endRoom), isValid else { return 0 }
        return end - start + 1
    }
    
    var displayText: String {
        if isValid {
            return "\(startRoom)-\(endRoom) (\(roomCount) rooms)"
        } else {
            return "Invalid range"
        }
    }
}

struct RoomSetupView: View {
    let hotelId: UUID
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var databaseService = DatabaseService()
    
    @State private var hotelName = ""
    @State private var roomRanges: [RoomRange] = [RoomRange()]
    
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    
    private var totalRoomCount: Int {
        roomRanges.filter { $0.isValid }.reduce(0) { $0 + $1.roomCount }
    }
    
    private var hasOverlappingRanges: Bool {
        let validRanges = roomRanges.compactMap { range -> ClosedRange<Int>? in
            guard let start = Int(range.startRoom), let end = Int(range.endRoom), range.isValid else { return nil }
            return start...end
        }
        
        for i in 0..<validRanges.count {
            for j in (i+1)..<validRanges.count {
                if validRanges[i].overlaps(validRanges[j]) {
                    return true
                }
            }
        }
        return false
    }
    
    private var isFormValid: Bool {
        return !roomRanges.isEmpty &&
               roomRanges.allSatisfy { $0.isValid } &&
               !hasOverlappingRanges &&
               totalRoomCount > 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "door.left.hand.open")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Room Setup")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if !hotelName.isEmpty {
                                Text(hotelName)
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Define your room ranges")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Room Ranges
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Room Ranges")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(Array(roomRanges.enumerated()), id: \.element.id) { index, range in
                            RoomRangeRow(
                                range: $roomRanges[index],
                                canDelete: roomRanges.count > 1,
                                onDelete: {
                                    roomRanges.remove(at: index)
                                }
                            )
                        }
                        
                        // Add Range Button
                        Button(action: {
                            roomRanges.append(RoomRange())
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Range")
                                    .font(.headline)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Validation Messages
                        if hasOverlappingRanges {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Room ranges cannot overlap!")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Summary
                        if totalRoomCount > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                    Text("Total: \(totalRoomCount) rooms")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                
                                let validRanges = roomRanges.filter { $0.isValid }
                                if !validRanges.isEmpty {
                                    Text("Ranges: " + validRanges.map { $0.displayText }.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Create Rooms Button
                        Button(action: {
                            Task { await createRooms() }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                }
                                
                                Text(isLoading ? "Creating Rooms..." : "Create Rooms")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid && !isLoading ? Color.blue : Color.gray)
                            .cornerRadius(10)
                        }
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: 600)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
        .task {
            await loadHotelInfo()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success!", isPresented: $showingSuccess) {
            Button("Continue") {
                navigationManager.navigate(to: .roomDashboard(hotelId: hotelId))
            }
        } message: {
            Text("Successfully created \(totalRoomCount) rooms for \(hotelName)!")
        }
    }
    
    @MainActor
    private func loadHotelInfo() async {
        do {
            let hotel = try await databaseService.getHotel(id: hotelId)
            hotelName = hotel.name
        } catch {
            errorMessage = "Failed to load hotel information: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    @MainActor
    private func createRooms() async {
        isLoading = true
        
        do {
            try await databaseService.createRooms(hotelId: hotelId, ranges: roomRanges)
            showingSuccess = true
        } catch {
            errorMessage = "Failed to create rooms: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
}

struct RoomRangeRow: View {
    @Binding var range: RoomRange
    let canDelete: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Start Room
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("100", text: $range.startRoom)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(height: 44)
                }
                
                // Arrow
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                    .font(.title2)
                    .padding(.top, 16)
                
                // End Room
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("150", text: $range.endRoom)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(height: 44)
                }
                
                // Delete Button
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 16)
                }
            }
            
            // Range Status
            HStack {
                if range.isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(range.displayText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !range.startRoom.isEmpty || !range.endRoom.isEmpty {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("Check your numbers")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(range.isValid ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    RoomSetupView(hotelId: UUID())
        .environmentObject(NavigationManager(path: .constant(NavigationPath())))
}