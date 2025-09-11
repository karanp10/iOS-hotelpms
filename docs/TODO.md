# Login Flow Implementation Plan

## Overview
Implementing a unified login screen with separate account creation paths for Managers and Employees, following CLAUDE.md principles of simple, minimal changes.

## Step-by-Step Plan

### Phase 1: Core Login Flow ✅ COMPLETED
- [x] 1. **Modify LoginView.swift** 
  - Add "Create Account" button below existing Sign In button
  - Keep existing email/password fields and Sign In functionality
  - Simple addition, minimal code impact
  - **Status:** ✅ Added outlined "Create Account" button below Sign In

- [x] 2. **Create AccountSelectionView.swift**
  - New SwiftUI view with two main options:
    - "Create Manager Account" (leads to hotel creation)
    - "Join as Employee" (leads to hotel selection)
  - Clean, simple UI matching existing LoginView style
  - **Status:** ✅ Created with building/person badge icons, clean UI

- [x] 3. **Stop for Verification**
  - Review progress with user before continuing
  - Ensure navigation and UI work as expected
  - **Status:** ✅ Ready for user verification

### Phase 2: Redesigned Multi-Step Account Creation
- [x] 4. **Create ManagerSignupView.swift** - DEPRECATED
  - **Status:** ⚠️ Replaced with multi-step flow below

- [x] 5. **Create PersonalInfoView.swift** 
  - Step 1: Personal information collection
  - Name, email, password, confirm password
  - Clean single-purpose screen
  - **Status:** ✅ Created clean form with side-by-side name fields
  - **Stop for validation after completion**

- [x] 6. **Create HotelInfoView.swift**
  - Step 2: Hotel business setup 
  - Hotel name (with uniqueness validation)
  - Location, address, contact details
  - Professional business information
  - **Status:** ✅ Created with Basic Info + Location sections, scrollable
  - **Stop for validation after completion**

- [x] 7. **Create AccountSuccessView.swift**
  - Step 3: Welcome/success screen
  - Account creation confirmation
  - Next steps guidance
  - **Status:** ✅ Created with email verification notice & Sign In button

- [x] 8. **Update Navigation Flow**
  - Connect PersonalInfo → HotelInfo → Success
  - Remove separate manager/employee paths
  - Single account creation flow
  - **Status:** ✅ Complete navigation system with data passing

- [ ] 9. **Remove ManagerSignupView.swift** 
  - Clean up deprecated single-form approach

## Key Principles (from CLAUDE.md)
- Make every change as simple as possible
- Each task impacts minimal code
- Focus on simplicity over complexity
- Get verification at checkpoints

## Current Status
- ✅ Phase 1 Complete (Steps 1-3)
- 🔄 Redesigned approach: Multi-step account creation
- 📋 Single account type, admin manages roles later
- 📁 Documentation now properly organized in docs/ folder

## Design Philosophy Change
- ❌ Old: Predict user roles during signup
- ✅ New: Professional business setup → role management post-signup
- 🎯 Focus: Clean UX with proper hotel business information

## Files Modified/Created
- ✅ `iOS-hotelpms/LoginView.swift` - Added Create Account button
- ✅ `iOS-hotelpms/AccountSelectionView.swift` - New selection screen
- ✅ `docs/TODO.md` - This file (testing docs folder structure)