# Product.md — Hotel PMS (SwiftUI + Supabase) — MVP (Two-Workflow Model)

## 0. Purpose
Deliver an iOS **Hotel Room Tracker** app that enables staff to log in, see the board of rooms, update **Occupancy** and **Cleaning** workflows, toggle flags (maintenance, DND, etc.), leave notes, and view a real-time audit trail. The design prioritizes simplicity, offline reliability, and staff-friendly workflows.

---

## 1. Executive Summary
We are migrating from Flutter to **SwiftUI** (iOS 17+). Supabase provides Auth, PostgREST, and Realtime.  

We adopt **two workflows**:  
- **Occupancy**: who’s in the room (vacant, assigned, occupied, stayover, checked_out).  
- **Cleaning**: readiness of the room (dirty, cleaning_in_progress, inspected).  
- **Flags**: overlays for exceptional states (maintenance, OOO, OOS, DND, lockout, VIP).  

Front Desk has access to both workflows for flexibility.  

---

## 2. Scope (MVP & V1.1)
### Must-Have (MVP)
- Secure login (Supabase Auth, email/password or magic link).
- Room Board (grid/list) with Occupancy + Cleaning + Flags visible.
- Filters (occupancy, cleaning, floor, flags, assignee, search by room #).
- Room Detail: change occupancy, cleaning, toggle flags, add notes.
- Realtime sync across all devices.
- Audit trail (status, flags, notes with who/when).
- Basic roles/permissions.
- Offline cache and queued writes with retries.
- Daily reset (manual button: set post-checkout rooms → dirty).
- Bulk actions (multi-select → apply changes).

### Should-Have (V1.1)
- Quick actions (assign, bulk flag).
- Undo snackbars.
- Push notifications.

---

## 3. Users & Roles
- **Front Desk**: full view, can edit occupancy + cleaning, notes, bulk actions.  
- **Housekeeping**: assigned rooms, edit cleaning states, add notes.  
- **Maintenance**: flagged rooms, set maintenance/OOO/OOS, add notes/photos.  
- **Manager/Admin**: full control, manage users, view reports.  

---

## 4. Two-Workflow Model

### Occupancy (enum)
- vacant  
- assigned  
- occupied  
- stayover  
- checked_out  

### Cleaning (enum)
- dirty  
- cleaning_in_progress  
- inspected  

### Flags (array of enums)
- maintenance_required  
- out_of_order (OOO)  
- out_of_service (OOS)  
- dnd  
- lockout  
- vip  
- rush  

**Guardrails:**  
- Notes required when moving to OOO or maintenance.  
- Warn when cleaning is set while DND is active.  

---

## 5. Permissions Matrix
| Action | Front Desk | Housekeeping | Maintenance | Manager/Admin |
|--------|------------|--------------|-------------|---------------|
| View all rooms | ✅ | ✅ | ✅ | ✅ |
| Set Occupancy | ✅ | ❌ | ❌ | ✅ |
| Set Cleaning | ✅ | ✅ | ❌ | ✅ |
| Toggle Maintenance/OOO/OOS | ✅ | ⚠️ (maintenance_required only) | ✅ | ✅ |
| Toggle DND/Lockout/VIP/Rush | ✅ | ✅ (except Lockout) | ✅ (no VIP/Rush) | ✅ |
| Add notes | ✅ | ✅ | ✅ | ✅ |
| Manage users | ❌ | ❌ | ❌ | ✅ |

---

## 6. Architecture
- **App:** SwiftUI (iOS 17+), Swift Concurrency.  
- **State:** SwiftUI `@Observable`, MVVM.  
- **Networking:** `supabase-swift`.  
- **Persistence:** SwiftData (cache + outbox).  
- **Realtime:** Supabase subscriptions (rooms, notes, events).  
- **Logging:** `OSLog`.  
- **Navigation:** `NavigationStack`.  

**Folder Layout**

## 7. Dependencies
- supabase-swift  
- KeychainAccess (optional)  
- SwiftLint  
- SnapshotTesting  
- Quick + Nimble (optional)  

## 8. Database Model (Supabase)

### hotels
- id uuid PK  
- name text  
- created_by uuid  
- created_at timestamptz  

### profiles
- id uuid PK  
- hotel_id uuid FK  
- first_name text  
- last_name text  
- email text unique  
- role text (admin, manager, front_desk, housekeeping, maintenance)  
- created_at timestamptz  

### rooms
- id uuid PK  
- hotel_id uuid FK  
- room_number text  
- floor int  
- type text  
- occupancy_status text enum  
- cleaning_status text enum  
- flags text[]  
- assignee_id uuid (optional)  
- updated_by uuid FK  
- updated_at timestamptz  

### room_notes
- id uuid PK  
- room_id uuid FK  
- author_id uuid FK  
- body text  
- created_at timestamptz  

### room_events (audit)
- id uuid PK  
- room_id uuid FK  
- actor_id uuid FK  
- event_type text (occupancy_changed, cleaning_changed, flag_added, flag_removed, note_added)  
- prev_value text/jsonb  
- new_value text/jsonb  
- reason text  
- created_at timestamptz  

---

## 9. Core Features
- **Auth:** login/logout with Supabase.  
- **Room Board:** occupancy + cleaning + flags per card.  
- **Room Detail:** segmented pickers for occupancy/cleaning, chips for flags, notes, mini history.  
- **Realtime:** subscribe to rooms, notes, events.  
- **Audit:** timeline per room, filterable.  
- **Offline:** SwiftData cache + outbox.  
- **Daily Reset:** batch RPC: set checked_out → dirty.  

---

## 10. UI/UX Notes
- Two clear pickers (Occupancy + Cleaning).  
- Flag chips with icons.  
- Swipe actions on RoomCard.  
- Large tap targets.  

---

## 11. Non-Functional
- Load ≤ 5s on LTE.  
- Update RTT ≤ 2s.  
- Retry on failures.  
- RLS for security.  
- Accessibility (Dynamic Type, VoiceOver).  

---

## 12. Testing
- Unit tests for ViewModels/Services.  
- Snapshot tests for RoomCard/Board/Detail.  
- Integration tests with Supabase dev.  
- SwiftLint in CI.  

---

## 13. Milestones
**Week 1–2:** Auth, read-only RoomBoard.  
**Week 3–4:** RoomDetail (two workflows + flags + notes), Realtime, Audit, Outbox.  
**Week 5:** Roles/permissions polish, Daily Reset, QA.  
**Week 6 (V1.1):** Bulk actions, polish.  

**Definition of Done:** all Must-Haves, RLS verified, TestFlight pilot build.  

---

## 14. Open Questions
- Require photos for maintenance resolution?  
- Enforce transitions server-side later?  
- CSV export in MVP? (default: no)
