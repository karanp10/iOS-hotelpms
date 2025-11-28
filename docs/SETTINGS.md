# Admin & Account Module Specification

## Overview

The Admin and Account modules provide hotel managers with comprehensive tools to manage staff, settings, and hotel operations, following our established MVVM architecture and development workflow.

### Core Features
- **Admin Tab** - Hotel management tools (Manager/Admin only)
- **Account Tab** - Personal settings (All users)
- **Role-based access control** - Leveraging existing `HotelRole` enum
- **iPad-optimized UI** - Split views, segmented controls, card-based layouts

---

## 1. Database Schema Analysis ✅

### Existing Tables (Fully Supported)
- ✅ **`hotels`** - Basic info, phone, address, city, state, zip
- ✅ **`profiles`** - User first/last name, email 
- ✅ **`hotel_memberships`** - Role assignments (admin, manager, front_desk, housekeeping, maintenance)
- ✅ **`join_requests`** - Pending/accepted/rejected status
- ✅ **`rooms`** - Room management with occupancy/cleaning status

### Missing Tables (Need Creation)
- ❌ **`hotel_settings`** - Workflow rules, timezone, checkout times
- ❌ **`notification_preferences`** - User notification settings
- ❌ **`app_preferences`** - Theme, language, accessibility settings

---

## 2. Navigation Structure

### Tab Layout
```
[ Status ] [ Recent Updates ] [ Admin ]* [ Account ]
```
*Admin tab visible only to managers/admin

### Admin Module Segments
```
[ Join Requests | Employees | Hotel Settings | Rooms ]
```

---

## 3. UI-First Implementation Plan

**Approach:** Build all UI components with mock data first, following existing patterns from the codebase, then connect to real functionality later. This ensures UI consistency and allows rapid design iteration before any database or service development.

### 3.1 Phase 1: UI Foundation & Navigation

#### Extend Existing Navigation Structure
- **Target:** Extend `AdminTabView.swift` to include Admin + Account tabs
- **Pattern:** Follow existing tab structure (Status, Recent Updates → Admin, Account)
- **Coordinator:** Update `AdminDashboardCoordinator.swift` for additional tab management
- **Access Control:** Admin tab visible only when `user.role.hasAdminAccess == true`

#### New Tab Structure
```swift
enum AdminTab: Hashable {
    case status
    case recentUpdates
    case admin        // NEW - Admin/Manager only
    case account      // NEW - All users
}
```

### 3.2 Phase 2: Core UI Components (Mock Data)

#### Admin Components (Following Existing Patterns)

**Join Request Components:**
- `JoinRequestCard.swift` - Individual request display (follows `RoomCard` pattern)
- `JoinRequestsList.swift` - List container (follows `RoomGridView` pattern)  
- `JoinRequestDetailSheet.swift` - Modal for approve/reject (follows `RoomDetailPanel` pattern)

**Employee Management Components:**
- `EmployeeCard.swift` - Staff member display with role chip
- `EmployeesList.swift` - Grouped by role sections
- `RoleSelectionSheet.swift` - Role picker modal
- `EmployeeDetailPanel.swift` - Split view detail pane

**Hotel Settings Components:**
- `HotelSettingsForm.swift` - iPad Settings.app style form
- `SettingsSection.swift` - Reusable form sections
- `WorkflowRulesPanel.swift` - Toggle switches and pickers
- `FlagConfigurationGrid.swift` - Enable/disable flag toggles

**Rooms Management Components:**
- `RoomsManagementGrid.swift` - Table/grid layout for room CRUD
- `AddRoomSheet.swift` - Room creation modal
- `BulkEditSheet.swift` - Multi-room operations
- `RoomTypeSelector.swift` - Room type picker

#### Account Components

**Profile & Settings Components:**
- `ProfileCard.swift` - User info display card
- `SettingsRow.swift` - Individual settings list items
- `PreferencesToggle.swift` - On/off switches for notifications
- `ThemeSelector.swift` - Light/Dark/System picker
- `MembershipsList.swift` - Hotel memberships display

#### Shared Components (Reusable)

**UI Primitives:**
- `SectionHeader.swift` - Consistent section styling across all admin/account views
- `DetailSheet.swift` - Base modal container for detail views  
- `ActionButton.swift` - Secondary button styles (extends `PrimaryButton`)
- `StatusChip.swift` - Extend existing chip pattern for admin statuses

### 3.3 Phase 3: Main View Structure

#### Admin Management View
```swift
struct AdminManagementView: View {
    @State private var selectedSegment: AdminSegment = .joinRequests
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented control: [ Join Requests | Employees | Hotel Settings | Rooms ]
            Picker("Admin Section", selection: $selectedSegment) {
                // Segmented picker
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Content based on selection
            switch selectedSegment {
                case .joinRequests: JoinRequestsList()
                case .employees: EmployeesList() 
                case .hotelSettings: HotelSettingsForm()
                case.rooms: RoomsManagementGrid()
            }
        }
    }
}
```

#### Account Settings View  
```swift
struct AccountSettingsView: View {
    var body: some View {
        // iOS Settings.app style layout
        NavigationView {
            List {
                ProfileCard()
                
                Section("Preferences") {
                    NavigationLink("Notifications", destination: NotificationSettings())
                    NavigationLink("Appearance", destination: AppearanceSettings())
                }
                
                Section("Account") {
                    NavigationLink("Hotels", destination: MembershipsList())
                    Button("Sign Out", role: .destructive) { /* logout */ }
                }
            }
            .navigationTitle("Account")
        }
    }
}
```

### 3.4 Phase 4: Comprehensive Mock Data

#### Mock Data Structure
```swift
// Mock data for all features
struct MockData {
    static let joinRequests: [JoinRequest] = [
        JoinRequest(name: "Sarah Johnson", email: "sarah@email.com", role: .frontDesk, status: .pending),
        // ... comprehensive mock data
    ]
    
    static let employees: [Employee] = [
        Employee(name: "Mike Chen", role: .manager, email: "mike@hotel.com"),
        // ... grouped by role with realistic data
    ]
    
    static let hotelSettings: HotelSettings = HotelSettings(
        checkoutTime: "11:00", 
        timezone: "EST",
        // ... all workflow rules with sensible defaults
    )
}
```

#### Rich SwiftUI Previews
```swift
#Preview("Join Requests - Loading") {
    JoinRequestsList()
        .previewDisplayName("Loading State")
}

#Preview("Join Requests - Populated") {
    JoinRequestsList()
        .previewDisplayName("With Data")
}

#Preview("Join Requests - Empty") {
    JoinRequestsList() 
        .previewDisplayName("No Pending Requests")
}
```

### 3.5 Phase 5: UI Component Patterns

#### Following Existing Codebase Patterns

**Card Components (from `RoomCard.swift`):**
- Consistent padding, corner radius, shadow styling
- Color coding for different states (pending, approved, etc.)
- Tap gestures and selection states
- Compressed/expanded modes for split views

**Form Components (from `OnboardingFormContainer.swift`):**
- Adaptive layout for different screen sizes
- Proper spacing and typography hierarchy  
- Auto-save detection and form validation states
- Consistent button styling using `PrimaryButton`

**List Components (from existing patterns):**
- Grouped sections with headers
- Search and filtering capabilities
- Empty state handling with appropriate messaging
- Loading states with skeleton views

**Navigation (from `AdminTabView.swift`):**
- Environment object injection for coordinators
- Proper tab management and state preservation
- Deep linking support for specific admin sections

### 3.6 UI Testing & Iteration Strategy

#### Preview-Driven Development
1. **Build each component in isolation** with comprehensive previews
2. **Test all UI states** (loading, empty, error, populated) in Xcode previews
3. **Verify iPad layouts** using device size previews
4. **Test role-based visibility** using mock user roles
5. **Validate accessibility** with VoiceOver and Dynamic Type

#### Design System Consistency
- **Colors:** Use existing blue primary, red destructive, gray secondary
- **Typography:** Follow existing font scales and weights
- **Spacing:** Consistent with current component spacing (8, 12, 16, 20px)
- **Animations:** Subtle, matching existing dashboard transitions

---

## 4. Feature Implementation Plan

### 4.1 Join Requests Management ✅ FEASIBLE

**Database Support:** ✅ Complete
- `join_requests` table with status (pending/accepted/rejected)
- Profile info available via `profiles` table

**UI Layout:**
- List of pending join requests
- Each row shows: Name, Email, Requested role, Date requested, Status chip
- Detail view with Approve/Reject buttons

**Implementation Steps:**
1. **Model:** `JoinRequest` model (already partially exists)
2. **Service:** `JoinRequestService` with approve/reject methods
3. **ViewModel:** `JoinRequestsViewModel` with list management
4. **View:** List with detail cards for approve/reject actions

**UI Components:**
- `JoinRequestsList` - Main list view
- `JoinRequestCard` - Individual request card
- `JoinRequestDetailModal` - Approval/rejection interface

### 4.2 Employee Management ✅ FEASIBLE

**Database Support:** ✅ Complete
- `hotel_memberships` with role field
- `profiles` for user details
- Role enum already defined in `HotelMembership.swift`

**UI Layout:**
- List grouped by role: Manager, Front Desk, Housekeeping, Maintenance
- Each row shows: Avatar, Name, Email, Current role chip
- Detail view with role picker and "Remove from Hotel" option

**Implementation Steps:**
1. **Service:** Extend `MembershipService` with role update/removal
2. **ViewModel:** `EmployeesViewModel` with role management
3. **View:** Grouped list by role with edit capabilities

**UI Components:**
- `EmployeesList` - Grouped by role
- `EmployeeCard` - Individual employee card
- `RoleSelectionSheet` - Role change interface

### 4.3 Hotel Settings ⚠️ PARTIALLY FEASIBLE

**Database Support:** ⚠️ Needs Extension
- ✅ Basic hotel info (name, address, phone) in `hotels` table
- ❌ Missing workflow rules, timezone, checkout times
- ❌ Missing flag configuration settings

**Sections:**
- **A. Basic Information:** Hotel Name, Address, Phone, Timezone, Default Checkout Time
- **B. Workflow Rules:** Required notes for Maintenance, Auto-dirty after checkout, Auto-stayover at midnight
- **C. Flags Configuration:** Enable/disable VIP, Rush, Lockout, DND, Maintenance, OOO, OOS flags
- **D. Branding (Future):** Hotel logo, accent colors, room card styling

**Required Database Migration:**
```sql
CREATE TABLE hotel_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id uuid REFERENCES hotels(id) NOT NULL,
  checkout_time time DEFAULT '11:00:00',
  timezone text DEFAULT 'UTC',
  require_maintenance_notes boolean DEFAULT false,
  require_ooo_notes boolean DEFAULT false,
  prevent_cleaning_with_dnd boolean DEFAULT true,
  auto_dirty_hours integer DEFAULT 2,
  auto_stayover_enabled boolean DEFAULT true,
  enabled_flags text[] DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

**Implementation Steps:**
1. **Migration:** Create `hotel_settings` table
2. **Model:** `HotelSettings` model with validation rules
3. **Service:** `HotelSettingsService` with CRUD operations
4. **ViewModel:** `HotelSettingsViewModel` with form handling
5. **View:** iPad "Settings.app" style form with sections

### 4.4 Rooms Management ✅ FEASIBLE

**Database Support:** ✅ Complete
- `rooms` table with room_number, floor_number
- Foreign key to hotels

**UI Layout:**
- Large "+ Add Room" button
- Table/grid showing: Room number, Floor, Type
- Room detail/edit with delete option
- Bulk actions for floor editing

**Implementation Steps:**
1. **Service:** Extend existing `RoomService` with CRUD operations
2. **ViewModel:** `RoomsManagementViewModel` with bulk operations
3. **View:** Table/grid with add/edit/delete capabilities

**UI Components:**
- `RoomsManagementList` - Main room grid
- `AddRoomSheet` - Room creation interface
- `BulkEditSheet` - Bulk operations interface

### 4.5 Account Settings ⚠️ PARTIALLY FEASIBLE

**Database Support:** ⚠️ Needs Extension
- ✅ Profile info (name, email) in `profiles` table
- ❌ Missing notification preferences
- ❌ Missing app preferences (theme, language)

**Sections:**
- **A. Profile:** First Name, Last Name, Email, Profile Picture
- **B. Security:** Change Password, Two-Factor Auth (future)
- **C. Notification Preferences:** Cleaning changes, Occupancy changes, Room assignments, Flag updates
- **D. App Preferences:** Light/Dark/System theme, Language, Accessibility options
- **E. Memberships:** Current hotels, Leave hotel, Request new hotel join, Switch active hotel
- **F. Logout**

**Required Database Migrations:**
```sql
CREATE TABLE notification_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES profiles(id) NOT NULL,
  cleaning_changes boolean DEFAULT true,
  occupancy_changes boolean DEFAULT true,
  room_assignments boolean DEFAULT true,
  flag_updates boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE app_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES profiles(id) NOT NULL,
  theme text DEFAULT 'system' CHECK (theme IN ('light', 'dark', 'system')),
  language text DEFAULT 'en',
  created_at timestamptz DEFAULT now()
);
```

---

## 5. Development Roadmap

### Phase 1: Core Admin Features ✅ Ready to Implement
- [ ] Join Requests Management
- [ ] Employee Management  
- [ ] Basic Hotel Info editing
- [ ] Rooms Management

### Phase 2: Enhanced Settings ⚠️ Requires DB Migration
- [ ] Create `hotel_settings` table
- [ ] Hotel workflow rules configuration
- [ ] Flag management system

### Phase 3: Account Preferences ⚠️ Requires DB Migration
- [ ] Create `notification_preferences` table
- [ ] Create `app_preferences` table
- [ ] Notification settings interface
- [ ] Theme/language selection

---

## 6. Architecture Alignment

Following `DEVELOPMENT_WORKFLOW.md`:

### 6.1 Models (`Models/`)
```
Models/
├── Admin/
│   ├── JoinRequest.swift ✅ (extend existing)
│   ├── HotelSettings.swift ❌ (new)
│   └── NotificationPreferences.swift ❌ (new)
├── Requests/Admin/
│   ├── JoinRequestRequests.swift ❌ (new)
│   ├── HotelSettingsRequests.swift ❌ (new)
│   └── EmployeeRequests.swift ❌ (new)
```

### 6.2 Services (`Services/`)
```
Services/
├── Admin/
│   ├── JoinRequestService.swift ❌ (new)
│   ├── EmployeeService.swift ❌ (new)
│   └── HotelSettingsService.swift ❌ (new)
├── Account/
│   ├── NotificationPreferencesService.swift ❌ (new)
│   └── AppPreferencesService.swift ❌ (new)
```

### 6.3 ViewModels (`ViewModels/`)
```
ViewModels/
├── Admin/
│   ├── JoinRequestsViewModel.swift ❌ (new)
│   ├── EmployeesViewModel.swift ❌ (new)
│   ├── HotelSettingsViewModel.swift ❌ (new)
│   └── RoomsManagementViewModel.swift ❌ (new)
├── Account/
│   └── AccountViewModel.swift ❌ (new)
```

### 6.4 Views (`Views/`)
```
Views/
├── AdminTabView.swift ❌ (new)
├── AccountTabView.swift ❌ (new)
├── Components/Admin/
│   ├── JoinRequestsList.swift ❌ (new)
│   ├── EmployeesList.swift ❌ (new)
│   ├── HotelSettingsForm.swift ❌ (new)
│   └── RoomsManagementGrid.swift ❌ (new)
├── Components/Account/
│   ├── ProfileSection.swift ❌ (new)
│   ├── NotificationSettings.swift ❌ (new)
│   └── AppPreferences.swift ❌ (new)
```

---

## 7. Role-Based Access Control

Using existing `HotelRole.hasAdminAccess`:

| Feature | Admin/Manager | Front Desk | Housekeeping | Maintenance |
|---------|---------------|------------|--------------|-------------|
| Status Tab | ✅ | ✅ | ✅ | ✅ |
| Recent Updates | ✅ | ✅ | ✅ | ✅ |
| **Admin Tab** | ✅ | ❌ | ❌ | ❌ |
| Join Requests | ✅ | ❌ | ❌ | ❌ |
| Employee Management | ✅ | ❌ | ❌ | ❌ |
| Hotel Settings | ✅ | ❌ | ❌ | ❌ |
| Rooms Management | ✅ | ❌ | ❌ | ❌ |
| **Account Tab** | ✅ | ✅ | ✅ | ✅ |

---

## 8. UI Style Guidelines

### iPad Layout Principles
- Large titles and sectioned lists
- Split views for editing (left: list, right: detail)
- Card-based layouts with consistent spacing
- Subtle animations matching iPadOS behavior

### Color System
- **Primary actions:** Blue (matching existing Status tab)
- **Destructive actions:** Red
- **Secondary actions:** Gray
- **Success states:** Green

### Component Patterns
- Follow existing patterns from `Views/Components/Dashboard/`
- Reuse chips, headers, filter menus from current codebase
- Toast/undo overlays for state feedback
- Form-like inputs with auto-save detection

---

## 9. Security Considerations

### Database Security
- Ensure Supabase RLS policies match UI role constraints
- Admin/Manager-only tables require `hasAdminAccess` checks
- Profile data limited to current user or admin access

### UI Security
- Role-based view visibility using `@Environment` user context
- Server-side validation for all mutations
- Audit logging for admin actions (role changes, deletions)

---

## 10. Next Steps

### Immediate Implementation (Phase 1)
1. **Extend navigation** - Add Admin/Account tabs to existing `AdminTabView.swift`
2. **Join Requests** - Build complete flow using existing `join_requests` table
3. **Employee Management** - Extend `MembershipService` for role updates
4. **Basic Rooms Management** - CRUD interface for existing room data

### Future Implementation (Phase 2/3)
1. **Database migrations** - Create `hotel_settings`, `notification_preferences`, `app_preferences` tables
2. **Enhanced settings** - Hotel workflow configuration with validation rules
3. **Account preferences** - Notifications, themes, and app settings

This specification leverages our existing database structure maximally while identifying clear extension points for advanced features. All implementation follows the established development workflow and maintains consistency with the current MVVM architecture.

