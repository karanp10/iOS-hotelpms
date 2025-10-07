# Hotel PMS - Split View iPad Dashboard Development Plan

## 🎯 MVP Scope & Key Constraints
**CRITICAL**: This is UI-only development for testing purposes. No actual database status changes will be implemented yet - we're building the interface first to validate the concept before connecting real data operations.

## 📋 Development Tasks (Actionable Steps)

### Phase 1: Core Layout Foundation
- [ ] **1.1** Set up NavigationSplitView or custom HStack for split-view layout
- [ ] **1.2** Create basic left pane with scrollable container for RoomCards
- [ ] **1.3** Create collapsible right pane for room details (hidden by default)
- [ ] **1.4** Implement "X" button to close right pane and restore single-pane view

### Phase 2: RoomCard Component
- [ ] **2.1** Design RoomCard layout with proper visual hierarchy:
  ```
  [ Room Number ]         [ Status Icon ]
  [ Occupancy Badge ]     [ Cleaning Badge ]
  [ Flags (if any) ]      
  [ Last Updated Time ]
  ```
- [ ] **2.2** Implement card background with subtle elevation/shadows
- [ ] **2.3** Add visual differentiation for active rooms (occupied/flagged)
- [ ] **2.4** Create LazyVGrid for efficient room card display

### Phase 3: Status Chips (Inline Actions)
- [ ] **3.1** Create tappable Occupancy chips (Vacant, Assigned, Occupied)
  - Color scheme: Vacant=Green 🟢, Occupied=Blue 🔵
- [ ] **3.2** Create tappable Cleaning chips (Dirty, In Progress, Inspected)
  - Color scheme: Dirty=Red 🔴, Inspected=Purple 🟣
- [ ] **3.3** Implement chip animations (scale/bounce/color pulse on tap)
- [ ] **3.4** Add toast notifications for status changes:
  - "Room 202 marked as Occupied ✅"
- [ ] **3.5** Ensure chips update status instantly WITHOUT opening detail panel

### Phase 4: Room Detail Panel (Right Pane)
- [ ] **4.1** Create detail panel that opens when RoomCard is tapped (outside chip area)
- [ ] **4.2** Display room info: number, floor, current statuses
- [ ] **4.3** Add segmented controls for Occupancy selection
- [ ] **4.4** Add segmented controls for Cleaning selection  
- [ ] **4.5** Implement multi-line Notes text field
- [ ] **4.6** Add instant save functionality (or Save button)

### Phase 5: Panel Transitions & Interactions
- [ ] **5.1** Implement smooth panel open/close animations
- [ ] **5.2** Handle room selection: clicking new card updates right pane content
- [ ] **5.3** Add success animations for detail panel actions:
  - Status updates → flash success check ✅
  - Note saves → brief "Saved" popup
- [ ] **5.4** Implement 3-second undo option after each action

### Phase 6: Visual Polish & Flags
- [x] **6.1** Implement flag system for critical states (OOO, DND, Maintenance)
- [x] **6.2** Add colored left border for flagged rooms (Orange 🟠 for maintenance)
- [x] **6.3** Add icon badges for flags (🔧 wrench, 🌙 moon)
- [x] **6.4** Create notes preview on cards (📝 icon or shortened text)


### Phase 7: Enhanced UX (Nice-to-Haves)
- [ ] **7.1** Add springy bounce animations to segmented controls
- [ ] **7.2** Implement auto-expanding notes field
- [ ] **7.3** Add subtle hover effects (if mouse/trackpad supported)
- [ ] **7.4** Create swipe actions on RoomCards for quick access
- [ ] **7.5** Implement vibrancy effects with material blur

## 🎨 Visual Design Specifications

### Color Palette (Accessible)
| Status Type | Value | Color | Emoji |
|-------------|-------|-------|-------|
| Occupancy | Vacant | Green 🟢 | |
| Occupancy | Occupied | Blue 🔵 | |
| Cleaning | Dirty | Red 🔴 | |
| Cleaning | Inspected | Purple 🟣 | |
| Flag | Maintenance | Orange 🟠 | 🔧 |

### Sample Chip Implementation
```swift
Text("Occupied")
  .padding(6)
  .background(Color.blue.opacity(0.2))
  .cornerRadius(12)
  .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue, lineWidth: 1))
```

## 🛠️ SwiftUI Implementation Guide
| Component | SwiftUI Tool |
|-----------|--------------|
| Split view | NavigationSplitView or custom HStack |
| RoomCard grid | LazyVGrid |
| Status chips | Button + Capsule + Icon |
| Detail panel | Form or custom VStack |
| State updates | @State or @Observable models per room |

## 📱 Sample Toast Messages
- "Room 210 set to In Progress 🧹"
- "Note saved to Room 105 📝"  
- "Flag DND removed from Room 301 🌙"

## ✅ Definition of Done
- Split-view layout functional on iPad
- RoomCards display with proper visual hierarchy
- Inline status chips work with animations
- Detail panel opens/closes smoothly
- All status changes show appropriate feedback
- UI responds instantly (no database calls)
- Code follows SwiftUI best practices and remains simple

---

## 📋 Phase 6 Review - Visual Polish & Flags (COMPLETED)

### Summary of Changes Made
Phase 6 has been successfully completed, delivering enhanced visual polish and a comprehensive flag system for the Hotel PMS room cards.

### Key Implementations

#### 6.1 Flag System Implementation ✅
- **Enhanced RoomFlag enum**: Already had proper system images and display names
- **Icons Added**: 🔧 (wrench) for maintenance, 🌙 (moon) for DND, ❌ for OOO/OOS
- **Critical States Supported**: Maintenance Required, Out of Order (OOO), Out of Service (OOS), Do Not Disturb (DND)
- **File Modified**: `Models/Room.swift` - flag system was already well-implemented

#### 6.2 Colored Left Border for Flagged Rooms ✅
- **Implementation**: Added `leftBorderOverlay` computed property to RoomCard
- **Visual Enhancement**: 6px colored left border for all flagged rooms
- **Color Priority System**:
  - 🟠 Orange for Maintenance Required (highest priority)
  - 🔴 Red for Out of Order/Out of Service
  - 🟣 Purple for Do Not Disturb
  - 🔵 Blue for other flags
- **File Modified**: `Views/Components/RoomCard.swift:75-79, 234-260`

#### 6.3 Enhanced Icon Badges for Flags ✅
- **Visual Improvements**: Enhanced flagsSection with better styling
- **Design Updates**:
  - Increased icon size to 10pt with semibold weight
  - Improved capsule design with subtle shadows
  - Added white border overlay for premium look
  - Better spacing and padding
- **File Modified**: `Views/Components/RoomCard.swift:193-228`

#### 6.4 Notes Preview on Cards ✅
- **Room Model Enhancement**: Added `notes` property to Room struct
- **New Computed Properties**:
  - `hasNotes`: Checks if room has meaningful notes
  - `notesPreview`: Truncates notes to 25 characters with ellipsis
- **UI Implementation**: Added `notesPreviewSection` with:
  - 📝 Note icon indicator
  - Truncated text preview
  - Subtle blue background styling
  - Positioned between flags and timestamp
- **Files Modified**: 
  - `Models/Room.swift:103, 115, 140, 160, 174, 206-214`
  - `Views/Components/RoomCard.swift:56-59, 230-254`
  - `Views/RoomDashboardView.swift` - Updated room creation calls
  
# 📘 Room Card UI Status System — Visual & Interaction Guidelines

This doc outlines a consistent and scalable status system for room cards in the iPad Hotel PMS dashboard.
It applies to **card borders, chips, flag icons, shadows, and selection logic.**

---

## ✅ 1. Visual Feedback Rules by Room Status

| Status    | Icon | Chip Color | Border/Glow                  | Notes                                          |
| --------- | ---- | ---------- | ---------------------------- | ---------------------------------------------- |
| Vacant    | 🟢   | Green      | None                         | Default state                                  |
| Occupied  | 🔵   | Blue       | Left border                  | Previously used full shadow; now blue bar only |
| Assigned  | 👤   | Gray       | None                         | Optional indicator                             |
| Dirty     | 🔺   | Red        | Orange border                | High urgency                                   |
| Cleaning  | 🧹   | Yellow     | Yellow border or pulsing dot | Needs visual in-progress cue                   |
| Inspected | 🟣   | Purple     | Purple subtle border         | Final cleaned state                            |

---

## ✅ 2. Border & Highlight Rules

### 📍 Border Types:

* Use **left-colored bar** (4px) for state indication
* Use **full border** (1pt) only for default design, not for status highlight
* Use **shadow or glow** only for selected room

### 💡 Example:

```swift
.overlay(Rectangle().frame(width: 4).foregroundColor(.yellow), alignment: .leading)
```

---

## ✅ 3. Chip Design Consistency

### 🔹 Chip Style:

* `Text + Icon`
* Font: `.caption`
* Padding: 8px horizontal, 4px vertical
* Background: Light tint of status color
* CornerRadius: 12

### 🔹 SwiftUI Example:

```swift
Text("🧹 Cleaning")
  .font(.caption)
  .padding(.horizontal, 8)
  .padding(.vertical, 4)
  .background(Color.yellow.opacity(0.2))
  .cornerRadius(12)
```

---

## ✅ 4. Flag System (Visual)

### 📍 Placement:

* Top-right inside RoomCard
* Left bar (orange or red) if flagged

### 📍 Icons:

* 🔧 = Maintenance
* 🌙 = DND
* 🚫 = Lockout
* ❌ = OOS

### 📍 RoomCard View:

```swift
if flags.contains("maintenance") {
  Text("🔧")
    .font(.caption2)
    .padding(4)
}
```

---

## ✅ 5. Room Detail View — Notes & Flag Layout

### 📝 Notes Field:

* Title: "📝 Notes"
* Use `TextEditor` inside rounded box
* Place Save button directly under with `.buttonStyle(.borderedProminent)`

### 🧩 Toggle Flag Buttons:

* Use `LazyVGrid(columns: [GridItem(.fixed(90))])`
* Consistent padding + height (min 36pt)
* Icon + label centered

---

## ✅ 6. Selection vs State

* **State = border / chip / icon**
* **Selection = card shadow or blue glow**
* Never mix the two (e.g., don't use shadow to indicate status)

---

## 📦 Optional Enhancements

* Add subtle animations on chip tap
* Add toast/snackbar for quick action feedback ("Room 110 set to Occupied ✅")
* Support theme contrast for yellow / purple (low readability on white)

---

### 🔚 End of Status System Guidelines


### Technical Implementation Details

#### Design Consistency
- All enhancements follow the existing design system
- Maintained accessibility with proper color contrast
- Used system colors and SF Symbols throughout
- Preserved existing animations and interactions

#### Code Quality
- Added computed properties for reusable logic
- Maintained separation of concerns
- Updated all Room initializers to handle notes
- Added comprehensive preview data for testing

#### Visual Hierarchy Improvements
1. **Flag Priority System**: Color-coded left borders indicate urgency
2. **Enhanced Flag Badges**: Better visual distinction with shadows and borders
3. **Notes Integration**: Subtle preview without overwhelming the card layout
4. **Improved Information Density**: Maximum information in minimal space

### Impact on User Experience
- **Staff Efficiency**: Instant visual identification of room issues via colored borders
- **Information Access**: Notes preview provides immediate context without navigation
- **Visual Clarity**: Enhanced flag badges improve readability and recognition
- **Consistent Interface**: All rooms follow the same visual pattern

### Next Steps
Phase 6 is complete and ready for testing. The implementation provides a solid foundation for Phase 7 (Enhanced UX) features. All visual polish requirements have been met with a focus on simplicity and staff usability.

---

## 📋 Phase 6.5 Review - UI Status System Updates (COMPLETED)

### Summary of Changes Made
Phase 6.5 successfully implemented the Room Card UI Status System guidelines, creating a consistent visual hierarchy and proper separation between state and selection indicators.

### Key Implementations

#### 6.5.1 Chip Corner Radius Update ✅
- **Updated corner radius**: Changed from 8px to 12px for all status chips
- **Consistency**: Both background corner radius and stroke corner radius updated
- **Files Modified**: `Views/Components/RoomCard.swift:154, 198`

#### 6.5.2 Assigned Occupancy Color Fix ✅
- **Color Change**: Updated assigned status from blue to gray (👤)
- **Differentiation**: Better visual distinction between Assigned (gray) and Occupied (blue)
- **Files Modified**: 
  - `Views/Components/RoomCard.swift:278`
  - `Views/RoomDashboardView.swift:873`

#### 6.5.3 Status-Based Left Borders Implementation ✅
- **Comprehensive Border System**: All room states now get appropriate left borders
- **Color Mapping**: 
  - Dirty → Orange border
  - Cleaning in Progress → Yellow border
  - Inspected → Purple border
  - Occupied → Blue border (via priority system)
  - Flags → Existing flag colors
- **Enhanced Logic**: Updated `shouldShowStatusBorder` to include all relevant states
- **Files Modified**: `Views/Components/RoomCard.swift:230-253, 256-285`

#### 6.5.4 Selection vs State Separation ✅
- **Clear Distinction**: Borders indicate state, shadows indicate selection
- **Selection Feedback**: Added `isSelected` parameter to RoomCard
- **Visual Selection**: Blue glow shadow for selected rooms
- **State Borders**: Removed state-dependent shadow variations
- **Files Modified**: 
  - `Views/Components/RoomCard.swift:3-22, 95-100, 318-356`
  - `Views/RoomDashboardView.swift:295`

#### 6.5.5 Priority System Implementation ✅
- **Priority Order**: Cleaning status > Occupancy status > Flags
- **Comprehensive Logic**: `statusBorderColor` function handles all priority levels
- **Smart Fallbacks**: Proper handling of edge cases through priority hierarchy
- **Files Modified**: `Views/Components/RoomCard.swift:256-285`

### Technical Implementation Details

#### Visual Hierarchy Improvements
1. **Status Indication**: Left borders provide immediate visual cues for room state
2. **Selection Clarity**: Blue glow clearly indicates which room is selected for detail view
3. **Priority Logic**: Cleaning status always takes precedence for urgent maintenance needs
4. **Color Consistency**: Gray for assigned creates better visual differentiation

#### Code Quality
- **Separation of Concerns**: State logic separated from selection logic
- **Extensible Design**: Priority system easily accommodates future status types
- **Minimal Impact**: Changes focused only on visual styling, no functional disruption
- **UI-Only Implementation**: No database interactions, perfect for testing phase

#### User Experience Impact
- **Staff Efficiency**: Instant visual identification of room priorities via color-coded borders
- **Reduced Confusion**: Clear distinction between "assigned" and "occupied" states
- **Selection Feedback**: Users can easily see which room they have selected
- **Visual Consistency**: All status chips follow the same 12px corner radius standard

### Compliance with Guidelines
✅ **Border Types**: 4px left borders for state indication only  
✅ **Chip Style**: Text + Icon, .caption font, 8px/4px padding, 12px corner radius  
✅ **Selection Logic**: Shadows for selection, borders for state - never mixed  
✅ **Priority System**: Cleaning > Occupancy > Flags hierarchy implemented  
✅ **UI-Only Changes**: No database operations, pure visual updates  

### Next Steps
Phase 6.5 provides the foundation for Phase 7 Enhanced UX features. The status system is now consistent, accessible, and follows the established design principles. Ready to proceed with advanced animations and interaction features.


