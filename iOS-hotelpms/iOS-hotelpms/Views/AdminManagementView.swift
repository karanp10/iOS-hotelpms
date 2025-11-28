import SwiftUI

enum AdminSegment: String, CaseIterable {
    case joinRequests = "Join Requests"
    case employees = "Employees"
    case hotelSettings = "Hotel Settings"
    case rooms = "Rooms"
}

struct AdminManagementView: View {
    let hotelId: UUID
    @State private var selectedSegment: AdminSegment = .joinRequests
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                Text("Admin Management")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Segmented control
                Picker("Admin Section", selection: $selectedSegment) {
                    ForEach(AdminSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue)
                            .tag(segment)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            // Content based on selection
            Group {
                switch selectedSegment {
                case .joinRequests:
                    JoinRequestsList(hotelId: hotelId)
                case .employees:
                    EmployeesList(hotelId: hotelId)
                case .hotelSettings:
                    HotelSettingsForm(hotelId: hotelId)
                case .rooms:
                    RoomsManagementGrid(hotelId: hotelId)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AdminManagementView(hotelId: UUID())
}