# Feature Development Workflow

This guide captures the process we now follow when expanding the iOS Hotel PMS app. The goal is to keep every new view, service, and model aligned with the refactored architecture described in `docs/REFACTOR.md`, so additions stay composable, testable, and Supabase-friendly.

---

## 1. Architecture Recap

- **Navigation-first shell** – `NavigationDestination` plus `NavigationManager` manage stack-based flows inside `ContentView.swift`. Every new screen should be reachable through this enum and injected navigator.
- **MVVM boundaries** – SwiftUI views stay declarative. State, derived collections, mutations, and side effects live in `@MainActor` view models (`ViewModels/*`).
- **Service registry** – `ServiceManager.shared` exposes feature-specific services (room, hotel, membership, notes, etc.) and tracks user-session context. View models request the services they need instead of reaching directly into Supabase clients.
- **Layered services** – Each domain has lightweight repositories for reads, mutation helpers for writes, and a façade service that the rest of the app consumes (see `Services/RoomService.swift` and `Services/Room/RoomRepository.swift`).
- **Typed models** – Entities live under `Models/`, enums under `Models/Enums/`, and wire-format request/response structs under `Models/Requests/`. Keep DB column name mapping localized to these files.
- **Composable UI** – Larger views are composed from focused components tucked under `Views/Components/<Feature>/`. Shared patterns (chips, headers, filter menus, toast/undo overlays) should be reused.

---

## 2. Standard Flow for a New Feature

1. **Model the data**
   - Create/extend entity structs plus supporting enums in `Models/`.
   - Add request DTOs under `Models/Requests/<Feature>/`.
   - Prefer immutable structs with helper computed properties for view-ready strings.

2. **Design the service surface**
   - If the feature talks to Supabase, add a repository (reads) and/or mutations helper (writes) similar to `RoomRepository`/`RoomMutations`.
   - Wrap them in a façade service (`FeatureService`) that exposes async methods returning domain models.
   - Define a dedicated `FeatureServiceError` enum so view models can present actionable errors.
   - Register the new service inside `ServiceManager` so view models can grab it through dependency injection.

3. **Author the view model**
   - Create an `ObservableObject` marked `@MainActor`.
   - Inject the dependencies it needs (normally `ServiceManager` plus IDs/context).
   - Declare `@Published` source-of-truth state, derived collections/computed helpers, and intent methods (`loadData`, `applyFilter`, `submit`, etc.).
   - Encapsulate navigation, toast/undo messaging, optimistic updates, and error handling here instead of in the SwiftUI view.
   - Keep long-running work in `Task {}` blocks or dedicated async functions, and reset loading flags in `defer` blocks where applicable.

4. **Compose the SwiftUI view**
   - Instantiate the view model with `@StateObject` so it survives view reloads.
   - Break complex layouts into components within `Views/Components/<Feature>/` (headers, lists, cards, panels).
   - Bind UI controls directly to the view model’s published properties and intent closures (e.g., `RoomDetailPanel` calling `viewModel.updateRoomCleaning`).
   - Show global overlays (toast stack, undo banner, alerts) via observed state rather than singletons.

5. **Wire up navigation & previews**
   - Add a new case to `NavigationDestination` and extend the `switch` inside `ContentView` so the navigator can push the view.
   - Prefer initializer-based dependency injection for IDs and context.
   - Provide a `#Preview` with stubbed IDs/services so designers can iterate without hitting the backend.

6. **Validate**
   - Smoke the happy-path flow in the simulator.
   - If you added Supabase queries, ensure each one is covered by a unit test or at least a Preview that exercises the builder logic.
   - Confirm analytics/audit logging happens alongside mutations (see `RoomDashboardViewModel.executeUndo` for reference).

---

## 3. Checklist When Adding Views / Services / Models

- [ ] Entities & enums live in `Models/`, requests in `Models/Requests/`.
- [ ] Services expose async/await APIs and centralized error enums.
- [ ] `ServiceManager` knows how to vend any new service.
- [ ] View models own all side effects, navigation, and derived state.
- [ ] Views are broken into testable components and never talk to Supabase directly.
- [ ] Toasts, undo banners, and alerts are driven by view-model state instead of global singletons.
- [ ] New navigation destinations are added to `NavigationDestination` + `.navigationDestination`.
- [ ] Preview providers compile using lightweight mock data.

---

## 4. Example: Adding a “Housekeeping Schedule” Feature

1. Define `HousekeepingTask`, `HousekeepingStatus`, and request structs under `Models/`.
2. Create `HousekeepingRepository` (reads) and `HousekeepingMutations` (writes) that call Supabase.
3. Wrap them in `HousekeepingService` and register it in `ServiceManager`.
4. Build `HousekeepingScheduleViewModel` that:
   - Loads tasks via the service.
   - Exposes filters (`selectedDate`, `assignedStaff`).
   - Provides intent methods (`assign`, `complete`, `undo`), plus toast/undo state.
5. Compose `HousekeepingScheduleView` with a summary header, filter bar, and task list extracted into components under `Views/Components/Housekeeping/`.
6. Add a `NavigationDestination.housekeepingSchedule(hotelId:)` case and wire it into `ContentView`.

By following these steps each time, we keep new functionality consistent with the recent refactors and avoid sliding back into monolithic SwiftUI files or god services.
