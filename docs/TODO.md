• Schema takeaways

  - join_requests.status only allows pending | accepted | rejected, while hotel_memberships.status uses pending |
    approved | rejected. Any approval path has to translate between those enums.
  - profiles no longer carries a hotel_id, so the current approve-join-request edge function (which writes to
    profiles.hotel_id) can’t succeed—there’s no such column.
  - To grant access, we must insert/update hotel_memberships rows; that’s where role and approval status live.

  Edge function gaps

  1. approve-join-request
      - Updates join_requests to accepted/rejected, but never creates a hotel_memberships row, so the employee
        still has no hotel access.
      - Attempts to set profiles.hotel_id, which doesn’t exist per docs/DB.md, so approvals will fail.
      - Uses open GET parameters (id, action) with a service-role key, so anyone who gets the link can approve/
        reject.
  2. notify-admin
      - Fetches hotel.hotel_name, but the column is name.
      - Sends the manager an email with links to the insecure approval function above; no employee notification
        is ever sent.
      - Doesn’t include the requested role, so the admin has zero context in-app unless the mobile client stores
        it elsewhere.

  Given that starting point, here’s a fresh implementation plan, aligned with docs/DEVELOPMENT_WORKFLOW.md.

  ———

  Implementation Plan

  1. Model the data (Workflow §2.1)
      - Add a real JoinRequest struct under Models/ and request DTOs under Models/Requests/Onboarding/, matching
        docs/DB.md (id, profileId, hotelId, status, createdAt). Include nested requester info for admin views.
      - Extend HotelMembership models to reference the existing JoinRequestStatus/MembershipStatus enums so the
        app can translate accepted ↔ approved.
  2. Design the service surface (Workflow §2.2)
      - Introduce a JoinRequestService (or extend MembershipService) with async APIs:
          - createJoinRequest(hotelId: UUID, role: HotelRole) → inserts join_requests (status pending), inserts
            a matching hotel_memberships row with status = pending, and invokes the notify-admin function (POST
            body containing hotel name, admin email, requester info, and a signed approval token).
          - fetchJoinRequests(hotelId:, status:) → joins profiles and returns admin-facing data.
          - approveJoinRequest(requestId:) / rejectJoinRequest(requestId:) → updates join_requests.status to
            accepted/rejected, toggles the related hotel_memberships.status to approved/rejected, and calls a new
            function (or extends the existing one) to email the employee about the decision.
      - Update ServiceManager to vend this service so onboarding/admin view models don’t touch Supabase directly.
  3. Fix and harden the Edge functions (before wiring the app)
      - notify-admin: select name instead of hotel_name; include the requester’s desired role; generate a one-
        time signed token (store in join_requests or a companion table) instead of exposing raw IDs; email the
        admin via Resend with approve/reject URLs containing that token.
      - approve-join-request: accept a POST body with the signed token, validate it, update join_requests.status,
        update the matching hotel_memberships.status, and call Resend to notify the employee of the outcome. Drop
        the profiles.hotel_id update entirely. Return an HTML confirmation like today.
      - Both functions should use env vars for any callback base URLs and handle errors with JSON/HTML responses
        for easier debugging.
  4. Author the view models (Workflow §2.3)
      - EmployeeJoinViewModel: wire its requestToJoin() to the new service method, collect the desired role, and
        expose state for “pending request exists”. On success, push a new JoinRequestPendingView.
      - JoinRequestsViewModel: back Views/Components/Admin/JoinRequestsList.swift with real data—load pending
        requests on appear, expose loading/error states, and call approve/reject service methods. Show toasts/
        alerts driven by published state.
  5. Compose the SwiftUI views (Workflow §2.4)
      - Add a JoinRequestPendingView (under Views/Components/Onboarding/) explaining that the hotel admin has
        been emailed and showing the selected hotel/role.
      - Update JoinRequestsList to consume the new view model, display counts from live data, and show action
        spinners/disable buttons while mutations run.
      - Ensure AccountSelectionView and LoginView route users with pending requests into the pending screen
        instead of looping back.
  6. Wire navigation & previews (Workflow §2.5)
      - Add a NavigationDestination.joinRequestPending(hotelName: String) case and hook it up in ContentView.
        Provide Previews for the pending view and the admin list using mock services that mimic the schema.
  7. Validate (Workflow §2.6)
      - Run through the join flow end-to-end in the simulator: submit a request, verify Supabase rows, ensure the
        admin email arrives with secure links, click approve/reject to confirm memberships are updated, and log
        the employee back in to confirm access.
      - Smoke-test the admin tab: pending requests load, approving updates the UI, and rejection also removes/
        persists correctly.

  This plan keeps us within the architecture guide: schema-aligned models, service façade, MVVM boundaries,
  reusable components, and proper navigation wiring before manual QA.
