
# Refactor Plan

This document captures the current problem areas in the codebase and the concrete steps required to address them. Prioritize the high‑impact view refactors first, then move on to the shared services/models cleanup so subsequent work can lean on a stable foundation.

---

## Goals
- Shrink overgrown SwiftUI files into composable views plus focused view models.
- Untangle domain services so each file has a single responsibility and can be tested in isolation.
- Consolidate duplicated models/stores to avoid drift across features.
- Establish a step-by-step execution plan so work can be split across contributors.

---

## High-Priority View Refactors

### ✅ COMPLETED - `Views/RoomDashboardView.swift` (1,287 LOC → 179 LOC)
**Issues**
- ✅ RESOLVED: UI layout, filtering, Supabase calls, undo/toast orchestration, and mutation logic all live in one file.
- ✅ RESOLVED: Hard to unit test because data loads and side-effects happen in the view body.

**Completed Actions**
1. ✅ Created `ViewModels/RoomDashboardViewModel.swift` that loads rooms/hotel info, tracks filters, performs mutations, and exposes derived collections (filtered rooms, roomsByFloor, availableFloors).
2. ✅ Moved all mutation helpers (`updateRoomOccupancy`, `updateRoomCleaning`, flag toggles, notes CRUD) into the view model; view now calls async methods via `@StateObject`.
3. ✅ Split UI into subviews and placed them under `Views/Components/Dashboard/`:
   - `RoomStatsHeader.swift` - Hotel name and quick stats display
   - `RoomFiltersView.swift` - Search and filter controls 
   - `RoomGridView.swift` - Room grid layout by floor
   - `RoomDetailPanel.swift` - Room detail sidebar with status controls
   - `NotesPanel.swift` - Notes input and display
   - `ToastStack.swift` - Toast notification overlay
   - `UndoBanner.swift` - Undo action banner
4. ✅ Extracted toast/undo logic into reusable components that other screens can leverage.

### ✅ COMPLETED - `Views/Components/RoomCard.swift` (386 LOC → 263 LOC)
**Issues**
- ✅ RESOLVED: Single component handled layout, animation state, badge logic, and business transitions for occupancy/cleaning.

**Completed Actions**
1. ✅ Separated presentation vs. behavior: RoomCard now lightweight, moved "next status" business logic to `RoomDashboardViewModel`.
2. ✅ Created dedicated chip subviews with shared styling under `Views/Components/Room/`:
   - `OccupancyChipView.swift` - Reusable occupancy status chip with animation
   - `CleaningChipView.swift` - Reusable cleaning status chip with animation
   - `FlagBadgeRow.swift` - Reusable flag badge display with overflow handling
3. ✅ Moved animation state into the individual chip subviews, simplifying the parent card and enabling reuse across the app.

### ✅ COMPLETED - `Views/RecentlyUpdatedView.swift` (413 LOC → 75 LOC)
**Issues**
- ✅ RESOLVED: Handled data fetching, filtering, grouping, empty states, and defined row components inline.

**Completed Actions**
1. ✅ Created `RecentlyUpdatedViewModel` that owns loading/error states, filtering, search text, grouped sections, and refresh logic.
2. ✅ Split UI into components under `Views/Components/RecentUpdates/`:
   - `RecentUpdatesHeader.swift` - Title, summary chips, and search/filter controls
   - `HistoryFilterMenu.swift` - Reusable filter dropdown with icons and selection state
   - `HistorySectionList.swift` - Grouped history list with section headers
   - `HistoryEntryRow.swift` - Individual history entry display with user avatars and type badges
   - `SummaryChip.swift` - Reusable status summary chips
3. ✅ Moved date-formatting helpers and `HistoryFilter` enum into the view model for centralized logic.
4. ✅ Extracted toast/undo logic into reusable components that other screens can leverage.

### ✅ COMPLETED - `Views/RoomSetupView.swift` (319 LOC → 59 LOC)
**Issues**
- ✅ RESOLVED: Bundled the `RoomRange` model, validation, overlap detection, Supabase writes, and UI all in one file.

**Completed Actions**
1. ✅ Created `Models/RoomRange.swift` with validation helpers and array extensions for overlap detection and total calculations.
2. ✅ Created `RoomSetupViewModel` that manages ranges, exposes validation state, and handles hotel info loading and room creation.
3. ✅ Split UI into components under `Views/Components/RoomSetup/`:
   - `RoomSetupHeader.swift` - Title, hotel name, and description display
   - `RoomRangesList.swift` - Dynamic list of room ranges with add/remove functionality
   - `RoomRangeRow.swift` - Individual range input with validation feedback
   - `ValidationSummary.swift` - Validation messages, totals, and create button
4. ✅ Main view now only handles navigation structure and component composition, delegating all business logic to view model.

---

## ✅ COMPLETED - Secondary View Cleanups

- **✅ COMPLETED - Onboarding/Auth views** (`PersonalInfoView`, `ManagerHotelSetupView`, `EmployeeJoinView`)
  - ✅ Created shared `OnboardingFormContainer` that factors out `GeometryReader + AdaptiveLayout` scaffolding.
  - ✅ Added dedicated view models for each screen to manage validation, API calls, and navigation events.
  - ✅ Extracted shared components under `Views/Components/Onboarding/`:
    - `FormHeader.swift` - Standardized title and subtitle display
    - `PrimaryButton.swift` - Reusable button with loading states
    - `AlertBanner.swift` - Centralized alert handling
    - `PasswordFields.swift` - Adaptive password input fields
    - `BasicInfoFields.swift` - Hotel basic information inputs
    - `LocationFields.swift` - Hotel location input fields
    - `SearchBar.swift` - Reusable search component
    - `HotelSearchResults.swift` - Hotel search results display

- **✅ COMPLETED - `Views/EmployeeJoinView.swift`**
  - ✅ Created `EmployeeJoinViewModel` that manages hotel search/request logic.
  - ✅ Moved `HotelCard` to `Views/Components/Hotel/HotelCard.swift`.
  - ✅ Created reusable `SearchBar` component for other screens.

- **✅ COMPLETED - `Views/ManagerHotelSetupView.swift`**
  - ✅ Created `ManagerHotelSetupViewModel` that manages focus state, validation, and Supabase calls.
  - ✅ Added input formatting/validation helpers shared across onboarding screens.

- **✅ COMPLETED - `Views/PersonalInfoView.swift`**
  - ✅ Created `PersonalInfoViewModel` that handles password validation and signup flow.
  - ✅ Centralized error messaging and navigation decisions in view model.

---

## ✅ COMPLETED - Service Layer Refactors

- **✅ COMPLETED - `Services/DatabaseService.swift` (508 LOC → Deprecated/Split)**
  - ✅ Split into domain-specific services:
    1. `ProfileService` – profile CRUD operations with ProfileServiceError enum
    2. `HotelService` – hotel CRUD + metadata operations with HotelServiceError enum  
    3. `MembershipService` – membership/join requests with MembershipServiceError enum
    4. `RoomBatchService` – room setup/bulk insert helpers with RoomBatchServiceError enum
  - ✅ Removed duplicated APIs (`getRooms`) - now properly delegated to `RoomService`
  - ✅ Moved DTOs into dedicated files under `Models/Requests/`:
    - `ProfileRequests.swift` - CreateProfileRequest
    - `HotelRequests.swift` - CreateHotelRequest
    - `MembershipRequests.swift` - CreateMembershipRequest, CreateJoinRequest
  - ✅ Updated all ViewModels and Views to use new domain services:
    - `RoomSetupViewModel`, `EmployeeJoinViewModel`, `ManagerHotelSetupViewModel` 
    - `RoomDashboardViewModel`, `HotelSelectionView`, `LoginView`
  - ✅ Updated `ServiceManager` to provide access to new domain services while maintaining backward compatibility

- **✅ COMPLETED - `Services/ServiceManager.swift`**
  - ✅ Converted into a lightweight dependency registry providing access to all domain services
  - ✅ Moved orchestration logic into feature-specific view models:
    - Room updates, flag toggles → `RoomDashboardViewModel` 
    - Notes saves → `RoomDashboardViewModel`
    - Audit logging → Integrated directly in ViewModels
  - ✅ Removed global error handling - errors now bubble up through individual ViewModels
  - ✅ Removed global loading states - ViewModels manage their own loading states
  - ✅ Maintained user context management (currentUserId, currentHotelId, getUserRole)

- **✅ COMPLETED - `Services/NotesService.swift`**
  - ✅ Converted to focus strictly on note CRUD operations
  - ✅ Removed audit logging - now delegated to AuditService in ViewModels
  - ✅ Moved request models to `Models/Requests/NotesRequests.swift`
  - ✅ Models already relocated to `Models/RoomHistory/RoomHistoryModels.swift`
  - ✅ Added proper error handling with `NotesServiceError` enum
  - ✅ Updated method signatures to return data for audit logging by callers
  - ✅ Updated `RoomDashboardViewModel` to handle audit logging separately through AuditService

- **✅ COMPLETED - `Services/AuditService.swift` + `Services/HistoryService.swift`**
  - ✅ Merged into a single `RoomHistoryService` responsible for both audit logging and history querying
  - ✅ Eliminated duplicated functionality between audit logging and history retrieval
  - ✅ Consolidated shared DTOs - now using single `RoomHistoryEntry` model and `CreateAuditRequest` 
  - ✅ Maintained all convenience methods for specific audit operations (occupancy, cleaning, flags, notes)
  - ✅ Added proper error handling with `RoomHistoryServiceError` enum
  - ✅ Updated `RoomDashboardViewModel` and `RecentlyUpdatedViewModel` to use new unified service
  - ✅ Removed old `AuditService.swift` and `HistoryService.swift` files after migration
  - ✅ Updated `ServiceManager` to provide `roomHistoryService` as single source for history operations

- **✅ COMPLETED - `Services/RoomService.swift`**
  - ✅ Split read vs. write responsibilities into `RoomRepository` and `RoomMutations` classes
  - ✅ Replaced bespoke Codable structs with generic `RoomPatch` helper and `RoomPatchBuilder` pattern
  - ✅ Eliminated code duplication from `RoomOccupancyUpdate`, `RoomCleaningUpdate`, `RoomFlagsUpdate`, `RoomBatchUpdate`
  - ✅ Created unified `RoomService` that combines repository and mutations while maintaining clean API
  - ✅ Added proper error handling with domain-specific `RoomServiceError` enum
  - ✅ Enhanced functionality with new methods: `getRoom()`, `getRoomsByFloor()`, `getRoomsByOccupancy()`, `getRoomsByCleaning()`, `getRoomsWithFlags()`, `searchRooms()`, `getRoomStats()`
  - ✅ Improved flag management with `setFlags()`, `addFlag()`, `removeFlag()` methods alongside `toggleFlag()`
  - ✅ Added batch operations support with `createRooms()` and `updateRoomBatch()`
  - ✅ Maintained backward compatibility with deprecated method signatures
  - ✅ No changes required to existing ViewModels - method signatures already matched new architecture

---

## ✅ COMPLETED - Models & Stores

- **✅ COMPLETED - `Models/Room.swift`**
  - ✅ Moved enums (`OccupancyStatus`, `CleaningStatus`, `RoomFlag`) into `Models/Enums/RoomEnums.swift`
  - ✅ Relocated request structs (`CreateRoomRequest`) into `Models/Requests/Room/RoomRequests.swift`
  - ✅ Kept `Room` focused on entity data + lightweight computed helpers

- **✅ COMPLETED - History Models**
  - ✅ Extracted `RoomHistoryEntry`, `RoomHistoryRequest`, and `RoomNote` from services into `Models/RoomHistory/RoomHistoryModels.swift`
  - ✅ Both activity feed and audit logging now share the same models/formatters
  - ✅ Removed duplicated model definitions from `HistoryService.swift` and `NotesService.swift`

- **✅ COMPLETED - `Stores/RoomStore.swift`**
  - ✅ Removed unused RoomStore entirely to avoid confusion
  - ✅ RoomDashboardViewModel already provides centralized room state management with optimistic updates
  - ✅ Single source of truth maintained without duplicate state management

---

## Execution Roadmap

1. **Dashboard + Card Refactor**
   - Build `RoomDashboardViewModel` and split `RoomDashboardView`/`RoomCard` into smaller components.
   - Introduce shared status UI helpers.

2. **History Feed Refactor**
   - Create `RoomHistoryService` + shared models.
   - Implement `RecentlyUpdatedViewModel` and extract feed components.

3. **Room Setup Flow**
   - Move `RoomRange` to models, add `RoomBatchService`, and refactor `RoomSetupView`.

4. **Onboarding/Auth Screens**
   - Build shared `OnboardingFormContainer`, per-screen view models, and shared components.

5. **Service Layer Split**
   - Break `DatabaseService` apart, adjust call sites, and simplify `ServiceManager`.

6. **Model/Store Cleanup**
   - Relocate enums/requests/history structs.
   - Remove or adopt `RoomStore`.

Each stage should include targeted unit/UI tests to cover the extracted view models and services before moving on.

---

## Post-Refactor Validation
- Audit SwiftUI previews to ensure new components render in isolation.
- Add unit tests for view models (filters, optimistic updates, undo states).
- Add integration tests for the refactored services (Supabase interactions mocked).
- Update documentation/README screenshots once the UI is split into modular components.

---

By following the steps above, the codebase moves from monolithic files toward modular, testable components with clear ownership boundaries.
