# Employee Views - Role-Based Interface Implementation Plan

## Overview

Implement employee-facing interface with four tabs, structured similarly to AdminTabView but tuned per role. Zero clutter, role-specific "main" tasks front and center.

**Constraints:**
- Schema: rooms (occupancy_status, cleaning_status, flags), room_history, room_notes, hotel_memberships - NO new tables
- Architecture: NavigationDestination + MVVM, services via ServiceManager, composable components
- Reuse: Existing RoomService, models, and admin component patterns

---

## Tab Structure for Employees

```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│   Primary    │   Activity   │ Requests/    │   Account    │
│  (Role-      │  (Filtered   │  Tasks       │  (Profile)   │
│  Specific)   │  Recent)     │  (Queued)    │              │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

### 1. Primary Tab (Role-Specific)

**Housekeeping - "My Rooms"**
- List/grid filtered to cleaning workflow (dirty/cleaning_in_progress/ready)
- Actions: Update cleaning_status, add housekeeping notes, toggle DND warning
- Quick search/filter by floor/flag
- Inline actions on room cards: "Start Cleaning" / "Mark Ready"

**Maintenance - "Issues"**
- Rooms with maintenance/OOO/OOS flags only
- Actions: Clear/resolve maintenance flag (removes flag + adds note), add maintenance note, set out_of_service
- Cleaning updates hidden to reduce noise

**Front Desk - "Board"**
- Simplified room board focused on occupancy + cleaning status
- Actions: Assign occupancy (check-in/out), toggle VIP/Rush flags, add notes
- Cannot modify cleaning_status directly

**Manager (non-admin) - "Board"**
- Mirror Front Desk view
- Add compact stats header
- No admin tab access

### 2. Activity Tab - "Recent Updates"

- Reuse `RecentlyUpdatedView` but filtered by role:
  - Housekeeping: cleaning status changes + notes
  - Maintenance: flag changes (maintenance/OOO/OOS) + notes
  - Front Desk: occupancy changes + notes
- Minimal controls: search/filter only

### 3. Requests/Tasks Tab - "Queued Work"

Derived from existing room data (no task table):

**Housekeeping - "Queued Cleaning"**
- Grouped sections: "Queued" (dirty, not in-progress) + "In Progress" (cleaning_in_progress)
- Quick actions: Start cleaning, Mark ready
- Priority: checked_out rooms shown first

**Maintenance - "Open Issues"**
- Derived from maintenance/OOO/OOS flags
- Quick action: Mark resolved (clears flag + adds completion note)
- Show most recent note for each issue

**Front Desk - "Arrivals/Departures"**
- Arrivals: rooms with occupancy_status = 'assigned' (not yet checked in)
- Departures: rooms with occupancy_status = 'checked_out' (needs cleaning coordination)
- Quick actions: Check in, Mark departed

### 4. Account Tab

- Reuse `AccountSettingsView` (profile info, hotel memberships)
- No admin management features

---

## UX Principles (Minimal Clutter)

1. **Single primary feed per role** - No nested tabs inside tabs
2. **Chips/filters, not drawers** - Inline filtering controls
3. **Action buttons on cards** - Context-specific actions directly on room cards
4. **Lightweight detail views** - Room detail shows only role-relevant controls
5. **Reuse components** - RoomCard variants with role-specific action rows

---

## Technical Implementation Plan

Following `docs/DEVELOPMENT_WORKFLOW.md` workflow:

### Phase 0: Role Configuration & Navigation Shell

**Goal:** Create EmployeeTabView with role-based tab configuration and navigation routing.

- [x] ✅ **0.1** Create `EmployeeTab` enum
  - **File:** `iOS-hotelpms/Models/Enums/EmployeeTab.swift` (NEW)
  - Define cases: `primary`, `activity`, `requests`, `account`
  - Add `label(for role:)` method to return role-specific tab titles
  - Add `systemImage(for role:)` for tab icons

- [x] ✅ **0.2** Create `EmployeeTabView.swift`
  - **File:** `iOS-hotelpms/Views/EmployeeTabView.swift` (NEW)
  - Similar structure to `AdminTabView`
  - Accept `hotelId` and `userRole` as init parameters
  - TabView with 4 tabs
  - Role-aware tab content switching

- [x] ✅ **0.3** Update navigation in `ContentView`
  - **File:** `iOS-hotelpms/Views/ContentView.swift` (MODIFY)
  - After login, check `ServiceManager.shared.currentUserRole?.hasAdminAccess`
  - If `true` → navigate to `AdminTabView`
  - If `false` → navigate to `EmployeeTabView`
  - Pass `hotelId` and `userRole` to EmployeeTabView

---

### Phase 1: Housekeeping - "My Rooms" (Primary Tab)

**Goal:** Housekeeping primary workspace showing cleaning workflow.

#### 1.1 Models & Helpers

- [x] ✅ **1.1.1** Create `CleaningPriority` enum
  - **File:** `iOS-hotelpms/Models/Enums/CleaningPriority.swift` (NEW)
  - Cases: `high` (checked_out), `medium` (dirty), `low` (cleaning_in_progress)
  - Add computed helper: `priority(for room: Room) -> CleaningPriority`

- [x] ✅ **1.1.2** Extend `Room` model with housekeeping helpers
  - **File:** `iOS-hotelpms/Models/Room.swift` (MODIFY)
  - Add computed property: `var cleaningPriority: CleaningPriority`
  - Add method: `func canStartCleaning() -> Bool`
  - Add method: `func canMarkReady() -> Bool`

#### 1.2 View Model

- [x] ✅ **1.2.1** Create `HousekeepingBoardViewModel`
  - **File:** `iOS-hotelpms/ViewModels/HousekeepingBoardViewModel.swift` (NEW)
  - Mark `@MainActor`, conform to `ObservableObject`
  - Inject `ServiceManager` and `hotelId` via init
  - **Published properties:**
    - `rooms: [Room]` - all rooms
    - `filteredRooms: [Room]` - filtered by search/floor
    - `isLoading: Bool`
    - `error: String?`
    - `searchText: String`
    - `selectedFloor: Int?`
    - `selectedStatus: CleaningStatus?`
  - **Computed properties:**
    - `dirtyRooms: [Room]` - status = dirty, sorted by priority
    - `inProgressRooms: [Room]` - status = cleaning_in_progress
    - `readyRooms: [Room]` - status = ready
    - `stats: (dirty: Int, inProgress: Int, ready: Int)`
  - **Intent methods:**
    - `func loadRooms() async`
    - `func startCleaning(roomId: UUID) async`
    - `func markReady(roomId: UUID) async`
    - `func addCleaningNote(roomId: UUID, note: String) async`
    - `func applyFilters()`

#### 1.3 SwiftUI Views & Components

- [x] ✅ **1.3.1** Create `HousekeepingBoardView`
  - **File:** `iOS-hotelpms/Views/Housekeeping/HousekeepingBoardView.swift` (NEW)
  - `@StateObject var viewModel: HousekeepingBoardViewModel`
  - Layout: VStack with stats header, filters, room list
  - Handle loading/error/empty states
  - Pull-to-refresh

- [x] ✅ **1.3.2** Create `CleaningStatsHeader`
  - **File:** `iOS-hotelpms/Views/Components/Housekeeping/CleaningStatsHeader.swift` (NEW)
  - Display stats: Dirty (red), In Progress (orange), Ready (green)
  - Horizontal grid of stat cards
  - Compact, visual design

- [x] ✅ **1.3.3** Create `CleaningRoomCard`
  - **File:** `iOS-hotelpms/Views/Components/Housekeeping/CleaningRoomCard.swift` (NEW)
  - Room number, floor, current cleaning status
  - Priority indicator (color-coded)
  - Inline action buttons:
    - "Start Cleaning" (if dirty/checked_out)
    - "Mark Ready" (if cleaning_in_progress)
  - Show latest note preview (1 line)
  - Tap to see room detail

- [x] ✅ **1.3.4** Create `CleaningFiltersBar`
  - **File:** `iOS-hotelpms/Views/Components/Housekeeping/CleaningFiltersBar.swift` (NEW)
  - Search bar
  - Floor filter (chip-based)
  - Status filter (All / Dirty / In Progress / Ready)
  - Horizontal ScrollView of filter chips

---

### Phase 2: Maintenance - "Issues" (Primary Tab)

**Goal:** Maintenance primary workspace showing rooms with maintenance flags.

#### 2.1 Models & Helpers

- [ ] **2.1.1** Extend `Room` model with maintenance helpers
  - **File:** `iOS-hotelpms/Models/Room.swift` (MODIFY)
  - Add computed property: `var hasMaintenanceFlag: Bool`
  - Add computed property: `var isOutOfService: Bool`
  - Add method: `func maintenanceFlags() -> [String]` (filters flags array)

#### 2.2 View Model

- [ ] **2.2.1** Create `MaintenanceIssuesViewModel`
  - **File:** `iOS-hotelpms/ViewModels/MaintenanceIssuesViewModel.swift` (NEW)
  - Mark `@MainActor`, conform to `ObservableObject`
  - Inject `ServiceManager` and `hotelId`
  - **Published properties:**
    - `rooms: [Room]` - only rooms with maintenance flags
    - `isLoading: Bool`
    - `error: String?`
    - `searchText: String`
    - `selectedFloor: Int?`
  - **Computed properties:**
    - `openIssues: [Room]` - rooms with unresolved maintenance flags
    - `oosRooms: [Room]` - out of service rooms
    - `stats: (openIssues: Int, oos: Int)`
  - **Intent methods:**
    - `func loadIssues() async`
    - `func resolveMaintenanceIssue(roomId: UUID, note: String) async` (removes maintenance flag + adds note)
    - `func setOutOfService(roomId: UUID, isOOS: Bool) async`
    - `func addMaintenanceNote(roomId: UUID, note: String) async`

#### 2.3 SwiftUI Views & Components

- [ ] **2.3.1** Create `MaintenanceIssuesView`
  - **File:** `iOS-hotelpms/Views/Maintenance/MaintenanceIssuesView.swift` (NEW)
  - `@StateObject var viewModel: MaintenanceIssuesViewModel`
  - Layout: Stats header, filters, issue list
  - Grouped sections: "Open Issues" / "Out of Service"

- [ ] **2.3.2** Create `MaintenanceStatsHeader`
  - **File:** `iOS-hotelpms/Views/Components/Maintenance/MaintenanceStatsHeader.swift` (NEW)
  - Display: Open Issues count, OOS count
  - Simple horizontal stat cards

- [ ] **2.3.3** Create `MaintenanceIssueCard`
  - **File:** `iOS-hotelpms/Views/Components/Maintenance/MaintenanceIssueCard.swift` (NEW)
  - Room number, floor
  - Show maintenance flags (maintenance, OOO, OOS)
  - Show most recent maintenance note (2 lines max)
  - Inline actions:
    - "Resolve" button (shows note input sheet)
    - "Mark OOS" toggle
  - Tap to see room detail

- [ ] **2.3.4** Create `MaintenanceFiltersBar`
  - **File:** `iOS-hotelpms/Views/Components/Maintenance/MaintenanceFiltersBar.swift` (NEW)
  - Search bar
  - Floor filter
  - Issue type filter (All / Maintenance / OOS)

---

### Phase 3: Front Desk - "Board" (Primary Tab)

**Goal:** Front desk primary workspace for occupancy management.

#### 3.1 Models & Helpers

- [ ] **3.1.1** Extend `Room` model with front desk helpers
  - **File:** `iOS-hotelpms/Models/Room.swift` (MODIFY)
  - Add computed property: `var isAvailable: Bool` (vacant + ready)
  - Add method: `func canCheckIn() -> Bool`
  - Add method: `func canCheckOut() -> Bool`

#### 3.2 View Model

- [ ] **3.2.1** Create `FrontDeskBoardViewModel`
  - **File:** `iOS-hotelpms/ViewModels/FrontDeskBoardViewModel.swift` (NEW)
  - Mark `@MainActor`, conform to `ObservableObject`
  - Inject `ServiceManager` and `hotelId`
  - **Published properties:**
    - `rooms: [Room]`
    - `isLoading: Bool`
    - `error: String?`
    - `searchText: String`
    - `selectedFloor: Int?`
    - `filterMode: OccupancyFilterMode` (enum: all, available, occupied, checkedOut)
  - **Computed properties:**
    - `availableRooms: [Room]` - vacant + ready
    - `occupiedRooms: [Room]` - occupied or stayover
    - `checkedOutRooms: [Room]` - checked_out (needs cleaning)
    - `stats: (available: Int, occupied: Int, checkedOut: Int)`
  - **Intent methods:**
    - `func loadRooms() async`
    - `func checkIn(roomId: UUID) async`
    - `func checkOut(roomId: UUID) async`
    - `func toggleVIPFlag(roomId: UUID) async`
    - `func addGuestNote(roomId: UUID, note: String) async`

#### 3.3 SwiftUI Views & Components

- [ ] **3.3.1** Create `FrontDeskBoardView`
  - **File:** `iOS-hotelpms/Views/FrontDesk/FrontDeskBoardView.swift` (NEW)
  - `@StateObject var viewModel: FrontDeskBoardViewModel`
  - Layout: Stats header, filters, room grid/list
  - Grouped sections by occupancy status

- [ ] **3.3.2** Create `OccupancyStatsHeader`
  - **File:** `iOS-hotelpms/Views/Components/FrontDesk/OccupancyStatsHeader.swift` (NEW)
  - Display: Available (green), Occupied (blue), Checked Out (orange)
  - Horizontal stat cards

- [ ] **3.3.3** Create `FrontDeskRoomCard`
  - **File:** `iOS-hotelpms/Views/Components/FrontDesk/FrontDeskRoomCard.swift` (NEW)
  - Room number, floor
  - Occupancy status badge
  - Cleaning status indicator (read-only, small chip)
  - VIP/Rush flag indicators
  - Inline actions:
    - "Check In" (if assigned/vacant)
    - "Check Out" (if occupied)
  - Tap to see detail

- [ ] **3.3.4** Create `OccupancyFiltersBar`
  - **File:** `iOS-hotelpms/Views/Components/FrontDesk/OccupancyFiltersBar.swift` (NEW)
  - Search bar
  - Floor filter
  - Quick filters: [Available] [Occupied] [Checked Out] [All]

---

### Phase 4: Activity Tab - "Recent Updates" (Filtered)

**Goal:** Role-filtered view of recent room changes.

- [ ] **4.1** Create `EmployeeActivityViewModel`
  - **File:** `iOS-hotelpms/ViewModels/EmployeeActivityViewModel.swift` (NEW)
  - Mark `@MainActor`, conform to `ObservableObject`
  - Inject `ServiceManager`, `hotelId`, and `userRole`
  - **Published properties:**
    - `updates: [RoomHistory]`
    - `isLoading: Bool`
    - `error: String?`
  - **Filter logic:**
    - Housekeeping: show only `change_type` = "cleaning_status" or "notes"
    - Maintenance: show only `change_type` = "flags" (maintenance-related) or "notes"
    - Front Desk: show only `change_type` = "occupancy_status" or "notes"
  - **Intent methods:**
    - `func loadRecentUpdates() async`

- [ ] **4.2** Create `EmployeeActivityView`
  - **File:** `iOS-hotelpms/Views/Employee/EmployeeActivityView.swift` (NEW)
  - Reuse `RecentlyUpdatedView` UI pattern
  - Pass filtered updates from view model
  - Minimal controls: search only

---

### Phase 5: Requests/Tasks Tab - "Queued Work"

**Goal:** Role-specific queued work derived from room data.

#### 5.1 Housekeeping - "Queued Cleaning"

- [x] ✅ **5.1.1** Create `HousekeepingQueueViewModel`
  - **File:** `iOS-hotelpms/ViewModels/HousekeepingQueueViewModel.swift` (NEW)
  - Mark `@MainActor`, conform to `ObservableObject`
  - Inject `ServiceManager`, `hotelId`
  - **Published properties:**
    - `queuedRooms: [Room]` - dirty, not in-progress (sorted by priority: checked_out first)
    - `inProgressRooms: [Room]` - cleaning_in_progress
    - `isLoading: Bool`
  - **Intent methods:**
    - `func loadQueue() async`
    - `func startCleaning(roomId: UUID) async`
    - `func markReady(roomId: UUID) async`

- [x] ✅ **5.1.2** Create `HousekeepingQueueView`
  - **File:** `iOS-hotelpms/Views/Housekeeping/HousekeepingQueueView.swift` (NEW)
  - Grouped sections: "Queued" + "In Progress"
  - Reuse `CleaningRoomCard` component
  - Pull-to-refresh

#### 5.2 Maintenance - "Open Issues"

- [ ] **5.2.1** Create `MaintenanceQueueViewModel`
  - **File:** `iOS-hotelpms/ViewModels/MaintenanceQueueViewModel.swift` (NEW)
  - Mark `@MainActor`, conform to `ObservableObject`
  - Inject `ServiceManager`, `hotelId`
  - **Published properties:**
    - `openIssues: [Room]` - rooms with maintenance/OOO/OOS flags
    - `isLoading: Bool`
  - **Intent methods:**
    - `func loadIssues() async`
    - `func resolveIssue(roomId: UUID, note: String) async`

- [ ] **5.2.2** Create `MaintenanceQueueView`
  - **File:** `iOS-hotelpms/Views/Maintenance/MaintenanceQueueView.swift` (NEW)
  - List of open issues
  - Reuse `MaintenanceIssueCard` component
  - "Resolve" action with note input sheet

#### 5.3 Front Desk - "Arrivals/Departures"

- [ ] **5.3.1** Create `FrontDeskQueueViewModel`
  - **File:** `iOS-hotelpms/ViewModels/FrontDeskQueueViewModel.swift` (NEW)
  - Mark `@MainActor`, conform to `ObservableObject`
  - Inject `ServiceManager`, `hotelId`
  - **Published properties:**
    - `arrivals: [Room]` - occupancy_status = 'assigned'
    - `departures: [Room]` - occupancy_status = 'checked_out'
    - `isLoading: Bool`
  - **Intent methods:**
    - `func loadQueue() async`
    - `func checkIn(roomId: UUID) async`
    - `func processDeparture(roomId: UUID) async`

- [ ] **5.3.2** Create `FrontDeskQueueView`
  - **File:** `iOS-hotelpms/Views/FrontDesk/FrontDeskQueueView.swift` (NEW)
  - Grouped sections: "Expected Arrivals" + "Departures (Need Cleaning)"
  - Reuse `FrontDeskRoomCard` component
  - Quick actions inline

---

### Phase 6: Role-Based Room Detail Panel

**Goal:** Modify existing room detail panel to show only role-relevant controls.

- [ ] **6.1** Create `RoomDetailPermissions` helper
  - **File:** `iOS-hotelpms/Models/Helpers/RoomDetailPermissions.swift` (NEW)
  - Static methods to determine what controls to show:
    - `canUpdateCleaning(role: HotelRole) -> Bool`
    - `canUpdateOccupancy(role: HotelRole) -> Bool`
    - `canManageFlags(role: HotelRole, flag: String) -> Bool`
    - `canAddNotes(role: HotelRole) -> Bool`
    - `canDeleteRoom(role: HotelRole) -> Bool` (admin only)

- [ ] **6.2** Update `RoomDetailPanel`
  - **File:** `iOS-hotelpms/Views/Components/RoomDetailPanel.swift` (MODIFY)
  - Accept optional `userRole: HotelRole?` parameter
  - Use `RoomDetailPermissions` to conditionally show/hide controls:
    - Housekeeping: Show cleaning status controls, hide occupancy controls
    - Maintenance: Show flag controls (maintenance only), hide cleaning/occupancy
    - Front Desk: Show occupancy controls, show cleaning status as read-only
    - Hide "Delete Room" button for non-admins

---

### Phase 7: Permission Enforcement in Services

**Goal:** Add role-based permission checks in ServiceManager.

- [ ] **7.1** Create `RoomOperation` enum
  - **File:** `iOS-hotelpms/Models/Enums/RoomOperation.swift` (NEW)
  - Cases: `updateCleaning`, `updateOccupancy`, `addRoom`, `deleteRoom`, `manageFlags`, `addNote`

- [ ] **7.2** Update `ServiceManager`
  - **File:** `iOS-hotelpms/Services/ServiceManager.swift` (MODIFY)
  - Add method: `func canPerform(_ operation: RoomOperation) -> Bool`
  - Check `currentUserRole` against operation type
  - Return `false` if user lacks permission

- [ ] **7.3** Update `RoomService` to enforce permissions
  - **File:** `iOS-hotelpms/Services/RoomService.swift` (MODIFY)
  - Before executing mutations, check `ServiceManager.shared.canPerform(_:)`
  - Throw `RoomServiceError.permissionDenied` if unauthorized
  - Add `.permissionDenied` case to `RoomServiceError` enum

---

### Phase 8: Wire Navigation & Integration

**Goal:** Connect all views to EmployeeTabView and ensure proper navigation flow.

- [ ] **8.1** Complete `EmployeeTabView` integration
  - **File:** `iOS-hotelpms/Views/EmployeeTabView.swift` (MODIFY)
  - Wire all 4 tabs to correct views based on role:
    - **Primary tab:**
      - Housekeeping → `HousekeepingBoardView`
      - Maintenance → `MaintenanceIssuesView`
      - Front Desk / Manager → `FrontDeskBoardView`
    - **Activity tab:** `EmployeeActivityView` (all roles)
    - **Requests tab:**
      - Housekeeping → `HousekeepingQueueView`
      - Maintenance → `MaintenanceQueueView`
      - Front Desk → `FrontDeskQueueView`
    - **Account tab:** `AccountSettingsView` (all roles)

- [ ] **8.2** Update `AdminTabView` to hide admin tab for employees
  - **File:** `iOS-hotelpms/Views/AdminTabView.swift` (MODIFY)
  - Add conditional check: only show "Admin" tab if `ServiceManager.shared.hasAdminAccess`
  - Note: May not be needed if we fully route employees to EmployeeTabView

- [ ] **8.3** Test navigation flow
  - Login as Housekeeping → should see EmployeeTabView with housekeeping views
  - Login as Maintenance → should see maintenance-specific views
  - Login as Front Desk → should see front desk views
  - Login as Manager (non-admin) → should see front desk views (no admin tab)
  - Login as Admin/Manager → should see AdminTabView

---

### Phase 9: Previews & Testing

**Goal:** Add SwiftUI previews for all new components and test workflows.

- [ ] **9.1** Add previews to all views
  - Create preview providers with mock data for:
    - `HousekeepingBoardView`
    - `MaintenanceIssuesView`
    - `FrontDeskBoardView`
    - `EmployeeActivityView`
    - Queue views (all 3 roles)
  - Use sample Room objects with various statuses/flags

- [ ] **9.2** Test housekeeping workflow
  - Load "My Rooms" → see dirty/in-progress/ready rooms
  - Tap "Start Cleaning" → room moves to in-progress
  - Tap "Mark Ready" → room becomes ready
  - Check Activity tab → see cleaning status changes

- [ ] **9.3** Test maintenance workflow
  - Load "Issues" → see only rooms with maintenance flags
  - Tap "Resolve" → add note, flag removed
  - Mark room OOS → flag added
  - Check Activity tab → see flag changes

- [ ] **9.4** Test front desk workflow
  - Load "Board" → see available/occupied/checked_out rooms
  - Tap "Check In" → occupancy changes to occupied
  - Tap "Check Out" → occupancy changes to checked_out
  - Check Activity tab → see occupancy changes

- [ ] **9.5** Test permission enforcement
  - Housekeeping user tries to check in room → should fail
  - Maintenance user tries to update cleaning status → should fail
  - Front desk tries to delete room → button hidden

---

## File Structure Summary

### New Files to Create

```
Models/
├── Enums/
│   ├── EmployeeTab.swift                    [0.1]
│   ├── CleaningPriority.swift               [1.1.1]
│   └── RoomOperation.swift                  [7.1]
├── Helpers/
│   └── RoomDetailPermissions.swift          [6.1]

ViewModels/
├── HousekeepingBoardViewModel.swift         [1.2.1]
├── MaintenanceIssuesViewModel.swift         [2.2.1]
├── FrontDeskBoardViewModel.swift            [3.2.1]
├── EmployeeActivityViewModel.swift          [4.1]
├── HousekeepingQueueViewModel.swift         [5.1.1]
├── MaintenanceQueueViewModel.swift          [5.2.1]
└── FrontDeskQueueViewModel.swift            [5.3.1]

Views/
├── EmployeeTabView.swift                    [0.2]
├── Housekeeping/
│   ├── HousekeepingBoardView.swift          [1.3.1]
│   └── HousekeepingQueueView.swift          [5.1.2]
├── Maintenance/
│   ├── MaintenanceIssuesView.swift          [2.3.1]
│   └── MaintenanceQueueView.swift           [5.2.2]
├── FrontDesk/
│   ├── FrontDeskBoardView.swift             [3.3.1]
│   └── FrontDeskQueueView.swift             [5.3.2]
├── Employee/
│   └── EmployeeActivityView.swift           [4.2]
└── Components/
    ├── Housekeeping/
    │   ├── CleaningStatsHeader.swift        [1.3.2]
    │   ├── CleaningRoomCard.swift           [1.3.3]
    │   └── CleaningFiltersBar.swift         [1.3.4]
    ├── Maintenance/
    │   ├── MaintenanceStatsHeader.swift     [2.3.2]
    │   ├── MaintenanceIssueCard.swift       [2.3.3]
    │   └── MaintenanceFiltersBar.swift      [2.3.4]
    └── FrontDesk/
        ├── OccupancyStatsHeader.swift       [3.3.2]
        ├── FrontDeskRoomCard.swift          [3.3.3]
        └── OccupancyFiltersBar.swift        [3.3.4]
```

### Files to Modify

```
Models/
└── Room.swift                               [1.1.2, 2.1.1, 3.1.1]

Services/
├── ServiceManager.swift                     [7.2]
└── RoomService.swift                        [7.3]

Views/
├── ContentView.swift                        [0.3]
├── AdminTabView.swift                       [8.2]
└── Components/
    └── RoomDetailPanel.swift                [6.2]
```

---

## Implementation Order & Milestones

### Milestone 1: Shell & Navigation (Phase 0)
- Create EmployeeTabView
- Add role-based routing in ContentView
- Verify employees land on correct view after login

### Milestone 2: Housekeeping Complete (Phases 1, 5.1)
- Implement "My Rooms" primary tab
- Implement "Queued Cleaning" requests tab
- Test full housekeeping workflow

### Milestone 3: Maintenance Complete (Phases 2, 5.2)
- Implement "Issues" primary tab
- Implement "Open Issues" requests tab
- Test full maintenance workflow

### Milestone 4: Front Desk Complete (Phases 3, 5.3)
- Implement "Board" primary tab
- Implement "Arrivals/Departures" requests tab
- Test full front desk workflow

### Milestone 5: Activity & Permissions (Phases 4, 6, 7)
- Implement filtered Activity tab
- Add role-based permissions to RoomDetailPanel
- Enforce permissions in ServiceManager

### Milestone 6: Integration & Testing (Phases 8, 9)
- Wire all tabs to EmployeeTabView
- Add previews
- End-to-end testing for all roles

---

## Architecture Alignment Checklist

Per `docs/DEVELOPMENT_WORKFLOW.md`:

- [x] Models & enums in `Models/`, helpers in `Models/Helpers/`
- [x] Services expose async/await APIs (reusing existing RoomService)
- [x] ServiceManager knows about permissions
- [x] View models own all side effects, navigation, derived state
- [x] Views broken into testable components
- [x] Navigation via EmployeeTabView routing
- [x] Preview providers for all new views
- [x] No new database tables (reuse existing schema)
- [x] Role-based UI with minimal clutter
- [x] Inline actions on cards, no nested tabs

---

## Open Questions

1. **Manager Role Tab Label:** Should non-admin managers see "Board" or "Manager Dashboard" for primary tab?
   - **Recommendation:** Use "Board" (same as Front Desk) to keep it simple

2. **Floor Filtering:** All roles get floor filters in "My Work" tabs?
   - **Recommendation:** Yes, useful for larger hotels

3. **Activity Tab Sharing:** Should we create one shared `EmployeeActivityView` for all roles, or 3 separate views?
   - **Recommendation:** One shared view with role-based filtering logic in view model

4. **Empty State Messages:** Role-specific empty states (e.g., "No rooms need cleaning" for housekeeping)?
   - **Recommendation:** Yes, context-specific messages improve UX

5. **Stats Header Click Behavior:** Should tapping a stat card filter the list below?
   - **Recommendation:** Yes, add tap gesture to filter (e.g., tap "Dirty: 8" → show only dirty rooms)

---

## Success Criteria

✅ Implementation complete when:

- [ ] Housekeeping user sees "My Rooms", can start/complete cleaning, sees queued tasks
- [ ] Maintenance user sees "Issues", can resolve maintenance flags, sees open issues
- [ ] Front desk user sees "Board", can check in/out, sees arrivals/departures
- [ ] All roles see filtered Activity tab with only relevant changes
- [ ] Role-based permissions enforced (housekeeping can't check in, front desk can't update cleaning, etc.)
- [ ] Room detail panel shows only role-appropriate controls
- [ ] Navigation routing works correctly based on user role
- [ ] All views have SwiftUI previews
- [ ] Zero database schema changes required
- [ ] Inline actions work correctly on all room cards
- [ ] Minimal clutter: single feed per tab, chip-based filters, no nested tabs

---

## Review Section

**Status:** Ready for approval and implementation

**Key Architectural Decisions:**
1. Reuse existing RoomService - no new services needed
2. Reuse Room model - add computed helpers only
3. Four-tab structure for all employee roles
4. Role-specific primary tab content
5. Shared Activity tab with role-based filtering
6. Permission enforcement in ServiceManager + UI layer
7. No database schema changes

**Simplicity Wins:**
- Single primary feed per role (no nested complexity)
- Inline actions on cards (context-aware, fast)
- Chip-based filters (visual, clear)
- Reuse existing components where possible
- Minimal new services/models

**Next Steps After Approval:**
1. Start with Phase 0 (EmployeeTabView shell)
2. Implement Housekeeping role first (Phases 1, 5.1) as reference pattern
3. Replicate pattern for Maintenance and Front Desk
4. Add Activity tab and permissions
5. Test and refine

