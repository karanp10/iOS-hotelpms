Hotel Join Request Feature - Complete Implementation Plan

 Overview

 Implement the complete hotel join request workflow: employees request to join hotels, admins approve/reject with role assignment, automated email notifications, and proper
 database synchronization between join_requests and hotel_memberships tables.

 Key Decisions (From User Requirements)

 ✅ Create hotel_memberships immediately - Both join_requests and hotel_memberships rows created with status='pending' when employee submits request
 ✅ Admin assigns role - Employee doesn't select role; admin chooses during approval
 ✅ Keep GET params - Use existing approach for email approve/reject links (no signed tokens)
 ✅ Complete implementation - All features from docs/TODO.md in one pass

 Database Flow

 Employee Requests:
   → INSERT join_requests (status: pending)
   → INSERT hotel_memberships (status: pending, role: null)
   → CALL notify-admin edge function

 Admin Approves:
   → UPDATE join_requests (status: accepted)
   → UPDATE hotel_memberships (status: approved, role: selected_role)
   → SEND employee notification email

 Admin Rejects:
   → UPDATE join_requests (status: rejected)
   → UPDATE hotel_memberships (status: rejected)
   → SEND employee notification email

 Status Translation: accepted (join_requests) → approved (hotel_memberships)

 ---
 Implementation Steps

 Phase 1: Models & Data Layer

 1. Create JoinRequest Model
 - File: Models/JoinRequest.swift (NEW)
 - Create JoinRequestStatus enum: pending, accepted, rejected
 - Create JoinRequest struct with Codable conformance
 - Create JoinRequestWithProfile struct (for admin views with nested profile data)
 - Add toMembershipStatus() helper for status translation

 2. Update Request Models
 - File: Models/Requests/MembershipRequests.swift (MODIFY)
 - Add UpdateJoinRequestRequest struct
 - Add UpdateMembershipStatusRequest struct

 Phase 2: Service Layer (Repository/Mutations/Facade Pattern)

 3. Create JoinRequestRepository
 - File: Services/JoinRequest/JoinRequestRepository.swift (NEW)
 - getPendingJoinRequests(hotelId:) - joins with profiles for admin view
 - getJoinRequest(id:) - fetch single request
 - hasPendingRequest(profileId:, hotelId:) - duplicate detection
 - Follow RoomRepository pattern

 4. Create JoinRequestMutations
 - File: Services/JoinRequest/JoinRequestMutations.swift (NEW)
 - createJoinRequest() - creates BOTH join_requests AND hotel_memberships (status=pending)
 - approveJoinRequest(requestId:, role:) - updates both tables (accepted/approved)
 - rejectJoinRequest(requestId:) - updates both tables to rejected
 - notifyAdmin(joinRequestId:) - calls edge function
 - Follow RoomMutations pattern

 5. Create JoinRequestService Facade
 - File: Services/JoinRequestService.swift (NEW)
 - Wraps repository and mutations with clean async API
 - Define JoinRequestServiceError enum with localized messages
 - Match RoomService structure exactly

 6. Update ServiceManager
 - File: Services/ServiceManager.swift (MODIFY)
 - Add @Published private(set) var joinRequestService: JoinRequestService
 - Initialize in init() alongside other services (line 36-46 pattern)

 Phase 3: View Models (MVVM Layer)

 7. Create JoinRequestsViewModel (Admin)
 - File: ViewModels/JoinRequestsViewModel.swift (NEW)
 - @Published properties: joinRequests, isLoading, showingError, selectedRequestId, selectedRole
 - loadJoinRequests() - fetch pending requests for hotel
 - startApproval(requestId:) - show role picker
 - confirmApproval() - call service.approveJoinRequest()
 - rejectRequest(requestId:) - call service.rejectJoinRequest()
 - Toast and error state management
 - Follow RoomDashboardViewModel pattern

 8. Update EmployeeJoinViewModel
 - File: ViewModels/EmployeeJoinViewModel.swift (MODIFY)
 - Add hasPendingRequest and pendingHotelName published properties
 - Update requestToJoin() to use ServiceManager.shared.joinRequestService
 - Navigate to .joinRequestPending(hotelName:) on success
 - Handle duplicate request errors

 Phase 4: Views (SwiftUI Layer)

 9. Create JoinRequestPendingView
 - File: Views/Components/Onboarding/JoinRequestPendingView.swift (NEW)
 - Shows "Request Pending" state with hotel name
 - Explains next steps (admin review, email notification)
 - "Back to Login" button navigates to root
 - Clean informational design

 10. Create RolePickerSheet
 - File: Views/Components/Admin/RolePickerSheet.swift (NEW)
 - Modal sheet for role selection during approval
 - Shows all HotelRole cases with descriptions
 - Confirm/Cancel buttons
 - Visual selection indicator

 11. Create ToastView (Reusable)
 - File: Views/Components/Shared/ToastView.swift (NEW)
 - Simple success toast with auto-dismiss
 - Reusable across app

 12. Update JoinRequestCard
 - File: Views/Components/Admin/JoinRequestCard.swift (MODIFY)
 - Change from JoinRequestMock to JoinRequestWithProfile
 - Remove role display (admin assigns on approval)
 - Add isProcessing parameter to disable buttons
 - Update to use real model properties

 13. Update JoinRequestsList
 - File: Views/Components/Admin/JoinRequestsList.swift (MODIFY)
 - Replace mock data with @StateObject var viewModel: JoinRequestsViewModel
 - Add role picker sheet (.sheet modifier)
 - Add toast overlay for success messages
 - Add error alert
 - Handle loading, empty, and error states

 Phase 5: Navigation

 14. Update ContentView
 - File: Views/ContentView.swift (MODIFY)
 - Add case joinRequestPending(hotelName: String) to NavigationDestination enum (after line 16)
 - Add case to switch statement in navigationDestination (around line 31-52)
 - Wire up JoinRequestPendingView

 Phase 6: Edge Functions (Supabase)

 15. Fix notify-admin Edge Function
 - File: supabase/functions/notify-admin/index.ts (MODIFY - via Supabase MCP)
 - Bug Fix: Change .select('hotel_name, created_by') → .select('name, created_by') (line 43)
 - Keep existing email template and Resend integration
 - Improve error handling

 16. Fix approve-join-request Edge Function
 - File: supabase/functions/approve-join-request/index.ts (MODIFY - via Supabase MCP)
 - Bug Fix: Remove entire profiles.hotel_id update block (lines 39-47)
 - Add: Query to get hotel_id from join_request
 - Add: Update hotel_memberships.status to 'approved' and set role when action='approve'
 - Add: Update hotel_memberships.status to 'rejected' when action='reject'
 - Add: Email notification to employee via Resend (success/rejection message)
 - Accept role as query parameter from email link (admin selects in app, which generates link)
 - Return improved HTML confirmation

 Phase 7: Testing & Validation

 End-to-End Testing Checklist:

 - Employee can search hotels and request to join
 - Request creates rows in both join_requests and hotel_memberships (status=pending)
 - notify-admin edge function sends email with correct hotel name
 - Admin sees pending requests in JoinRequestsList (no mock data)
 - Admin can tap Approve → role picker appears → confirm creates approval
 - Approval updates both tables: join_requests (accepted), hotel_memberships (approved + role)
 - Admin can tap Reject → both tables updated to rejected
 - Employee receives email notification of decision
 - Navigation to JoinRequestPendingView works
 - All loading states display properly
 - Error alerts show with clear messages
 - Toast messages appear and auto-dismiss

 ---
 Critical Files Summary

 | Priority | File Path                                        | Action | Purpose                                               |
 |----------|--------------------------------------------------|--------|-------------------------------------------------------|
 | 1        | Models/JoinRequest.swift                         | NEW    | Core domain model with status translation             |
 | 2        | Services/JoinRequest/JoinRequestMutations.swift  | NEW    | Creates both DB rows with status=pending              |
 | 3        | Services/JoinRequestService.swift                | NEW    | Service facade following Repository/Mutations pattern |
 | 4        | ViewModels/JoinRequestsViewModel.swift           | NEW    | Admin approval flow with role assignment              |
 | 5        | Views/Components/Admin/JoinRequestsList.swift    | MODIFY | Replace mock data with real view model                |
 | 6        | Services/ServiceManager.swift                    | MODIFY | Register joinRequestService (1 line add)              |
 | 7        | Views/ContentView.swift                          | MODIFY | Add .joinRequestPending navigation case               |
 | 8        | supabase/functions/approve-join-request/index.ts | MODIFY | Fix bugs, add hotel_memberships update                |
 | 9        | supabase/functions/notify-admin/index.ts         | MODIFY | Fix hotel.name query bug                              |

 ---
 Implementation Notes

 Simple, Focused Changes

 - Each file has a single, clear responsibility
 - Follow existing patterns (RoomService, RoomDashboardViewModel)
 - No over-engineering or extra features
 - Status translation handled in one place (JoinRequest model)

 Error Handling

 - JoinRequestServiceError enum for all service errors
 - Toast for success, alerts for errors
 - Graceful degradation if edge functions fail

 Architecture Alignment

 - Follows docs/DEVELOPMENT_WORKFLOW.md exactly
 - Repository/Mutations/Facade pattern like RoomService
 - MVVM boundaries maintained
 - Navigation via NavigationDestination enum
 - ServiceManager dependency injection

 ---
 Success Criteria

 ✅ Complete implementation when:
 - Employee → request → creates 2 DB rows (pending)
 - Admin → email → sees request with requester info
 - Admin → approve → selects role → both tables updated (accepted/approved + role)
 - Admin → reject → both tables updated (rejected)
 - Employee → receives email notification
 - All UI states handled (loading, empty, error, success)
 - No mock data remaining
 - Navigation flows work correctly
 - Edge functions fixed and tested
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
