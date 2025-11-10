
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

### `Views/RoomDashboardView.swift` (≈1,287 LOC)
**Issues**
- UI layout, filtering, Supabase calls, undo/toast orchestration, and mutation logic all live in one file.
- Hard to unit test because data loads and side-effects happen in the view body.

**Actions**
1. Create `RoomDashboardViewModel` that loads rooms/hotel info, tracks filters, performs mutations, and exposes derived collections (filtered rooms, roomsByFloor, availableFloors).
2. Move mutation helpers (`updateRoomOccupancy`, `updateRoomCleaning`, flag toggles, notes CRUD) into the view model; have the view call async methods via `@StateObject`.
3. Split UI into subviews (e.g., `RoomStatsHeader`, `RoomFiltersView`, `RoomGridView`, `RoomDetailPanel`, `NotesPanel`, `ToastStack`, `UndoBanner`) and place them under `Views/Components/Dashboard/`.
4. Extract the toast/undo logic into reusable components so other screens can leverage the same interactions.

### `Views/Components/RoomCard.swift` (≈386 LOC)
**Issues**
- Single component handles layout, animation state, badge logic, and business transitions for occupancy/cleaning.

**Actions**
1. Separate presentation vs. behavior: keep `RoomCardView` lightweight, and move “next status” calculations and Supabase triggers into the dashboard view model.
2. Create dedicated chip subviews (`OccupancyChipView`, `CleaningChipView`, `FlagBadgeRow`) with shared color/icon helpers so styles can be reused elsewhere.
3. Relocate animation state into the chip subviews (or remove if not essential) to simplify the parent card.

### `Views/RecentlyUpdatedView.swift` (≈413 LOC)
**Issues**
- Handles data fetching, filtering, grouping, empty states, and defines row components inline.

**Actions**
1. Add `RecentlyUpdatedViewModel` that owns loading/error states, filtering, search text, grouped sections, and refresh logic.
2. Break UI into `RecentUpdatesHeader`, `HistoryFilterMenu`, `HistorySectionList`, `HistoryEntryRow`, and `SummaryChip` components.
3. Move date-formatting helpers into either the view model or a small `HistoryFormatter`.

### `Views/RoomSetupView.swift` (≈319 LOC)
**Issues**
- Bundles the `RoomRange` model, validation, overlap detection, Supabase writes, and UI.

**Actions**
1. Move `RoomRange` plus validation helpers into `Models/RoomRange.swift`.
2. Introduce `RoomSetupViewModel` that mutates ranges, exposes validation state, and calls a dedicated service for room creation.
3. Keep the view responsible only for presenting fields, validation messaging, and invoking the view model’s async actions.

---

## Secondary View Cleanups

- **Onboarding/Auth views** (`PersonalInfoView`, `ManagerHotelSetupView`, `EmployeeJoinView`, `HotelSelectionView`, `LoginView`)
  - Factor out the shared `GeometryReader + AdaptiveLayout` scaffolding into an `OnboardingFormContainer`.
  - Give each screen a view model to manage validation, API calls, and navigation events instead of binding directly to `DatabaseService`/`AuthService`.
  - Extract shared components (form headers, primary buttons, alert banner) to reduce duplication.

- **`Views/EmployeeJoinView.swift`**
  - Move hotel search/request logic to `EmployeeJoinViewModel`.
  - Relocate `HotelCard` to `Views/Components/Hotel/HotelCard.swift`.
  - Introduce a reusable `SearchBar` component for other screens.

- **`Views/ManagerHotelSetupView.swift`**
  - Create `ManagerHotelSetupViewModel` that manages focus state, validation, and Supabase calls.
  - Share input formatting/validation helpers with other onboarding screens.

- **`Views/PersonalInfoView.swift`**
  - Offload password validation + signup flow to `PersonalInfoViewModel`.
  - Centralize error messaging and navigation decisions there.

---

## Service Layer Refactors

- **`Services/DatabaseService.swift` (≈508 LOC)**
  - Split into domain-specific services:
    1. `ProfileService` – profile CRUD.
    2. `HotelService` – hotel CRUD + metadata.
    3. `MembershipService` – membership/join requests.
    4. `RoomBatchService` – room setup/bulk insert helpers.
  - Remove duplicated APIs (`getRooms`) already implemented in `RoomService`.
  - Move DTOs (`CreateProfileRequest`, etc.) into dedicated files under `Models/Requests/`.

- **`Services/ServiceManager.swift`**
  - Convert into a lightweight dependency registry (or replace with dependency injection using protocols).
  - Move orchestration logic (room updates, flag toggles, notes saves) into feature-specific view models or coordinators.
  - Ensure errors bubble up through view models instead of global alerts inside the service manager.

- **`Services/NotesService.swift`**
  - Keep this class strictly about note CRUD.
  - Delegate audit logging to `AuditService` (pass a dependency in).
  - Relocate `RoomHistoryRequest`/`RoomNote` models to `Models/RoomHistory`.

- **`Services/AuditService.swift` + `Services/HistoryService.swift`**
  - Merge into a single `RoomHistoryService` responsible for both logging and querying.
  - Share request/response DTOs and avoid duplicating `RoomHistoryEntry` definitions.

- **`Services/RoomService.swift`**
  - Consider splitting read vs. write responsibilities (`RoomRepository` vs. `RoomMutations`).
  - Replace bespoke Codable structs (`RoomOccupancyUpdate`, `RoomCleaningUpdate`, etc.) with a generic patch helper or builder to reduce boilerplate.

---

## Models & Stores

- **`Models/Room.swift`**
  - Move enums (`OccupancyStatus`, `CleaningStatus`, `RoomFlag`) into `Models/Enums/`.
  - Relocate request structs (`CreateRoomRequest`) into `Models/Requests/Room`.
  - Keep `Room` focused on entity data + lightweight computed helpers.

- **History Models**
  - Extract `RoomHistoryEntry`, `RoomHistoryRequest`, and related helpers from services into `Models/RoomHistory/`.
  - Ensure both the activity feed and audit logging share the same models/formatters.

- **`Stores/RoomStore.swift`**
  - Currently unused; decide whether to reintroduce it as the single source of truth for room data (backed by `RoomService`) or remove it entirely to avoid confusion.
  - If retained, integrate it with the new dashboard view model so state is centralized.

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
