# iOS Hotel PMS - Onboarding Flow Implementation

## 🎯 Goal: Seamless signup → verification → role-based onboarding

## ✅ Completed Foundation Work
- ✅ Project organization (Views/, Services/, Models/ folders)
- ✅ Supabase integration (packages, SupabaseManager, AuthService, DatabaseService)
- ✅ Basic data models (Profile.swift, Hotel.swift)
- ✅ PersonalInfoView with validation
- ✅ Navigation infrastructure (ContentView, NavigationManager)

## 🔄 New Improved Onboarding Flow

### Problem We Solved:
- **Old flow**: Signup → immediate hotel creation → FAILED (user not verified)
- **New flow**: Signup → email verification → login → role selection → hotel setup

---

## 📋 Current Implementation: Fix Profile Creation Issue

### ❌ Current Problem (RESOLVED)
- Profile creation fails during signup due to timing/foreign key constraint issues
- User exists in auth.users but profiles table remains empty
- Error: "Failed to create profile, but user is created. Try logging in with email."

### ✅ Solution: Database Trigger + Auth Metadata (Supabase Best Practice)

### Phase 1: Database Setup (Clean Slate) ⏳
- [x] **Clear existing auth users and profiles data** - Fresh start
- [ ] **Create Postgres function** for auto-profile creation
- [ ] **Create trigger** that runs when user verifies email (email_confirmed_at is set)
- [ ] **Function reads** firstName/lastName from auth.users.raw_user_meta_data

### Phase 2: iOS Code Updates 🔧
- [ ] **Update AuthService.swift** - Add metadata parameter to signUp method
- [ ] **Update PersonalInfoView.swift** - Pass firstName/lastName as metadata, remove manual profile creation
- [ ] **Update DatabaseService.swift** - Remove profile creation from signup flow

### Phase 3: Testing ✨
- [ ] **Test complete flow**: Signup → Email verification → Login → Profile auto-exists
- [ ] **Verify error is resolved** and profiles table gets populated

### Phase 4: Continue with Original Onboarding Flow 🚀
- [ ] **EmailVerificationView** - "Check your email to verify account"
- [ ] **Update LoginView** - check memberships after successful login
- [ ] **AccountSelectionView** - Manager vs Employee choice (post-login only)
- [ ] **ManagerHotelSetupView** - hotel creation for managers
- [ ] **EmployeeJoinView** - join existing hotel by code/search

---

## 🏗️ New User Flow Architecture

### A. Signup (Anyone)
```
PersonalInfoView → AuthService.signUp() → EmailVerificationView
```

### B. Email Verification (Outside app)
```
User receives email → clicks link → email_confirmed_at set
```

### C. First Login (Critical routing)
```
LoginView → AuthService.signIn() → Check memberships:
├── Has memberships → Dashboard
└── No memberships → AccountSelectionView
```

### D. Manager Path
```
AccountSelectionView → ManagerHotelSetupView → Create hotel + membership → Dashboard
```

### E. Employee Path  
```
AccountSelectionView → EmployeeJoinView → Create join_request → PendingApprovalView
```

---

## 🗄️ Updated Database Design

### profiles (auto-created via trigger)
- id (uuid, PK, FK to auth.users)
- first_name, last_name, email, created_at

### hotels  
- id (uuid, PK)
- name, phone, address, city, state, zip_code
- created_by (uuid, FK to profiles.id), created_at

### hotel_memberships (role management)
- id (uuid, PK)
- profile_id (FK), hotel_id (FK)
- role (admin|manager|front_desk|housekeeping|maintenance)
- status (pending|approved|rejected), created_at
- UNIQUE(profile_id, hotel_id)

### join_requests (NEW - employee requests)
- id (uuid, PK)
- profile_id (FK), hotel_id (FK)  
- requested_role, status (pending|approved|rejected)
- note, created_at

---

## 🎯 Benefits of New Flow
- ✅ **No more authentication gaps** - profile always exists after signup
- ✅ **Clear role separation** - managers create hotels, employees join them
- ✅ **Better UX** - no confusing errors, clear next steps
- ✅ **Scalable** - users can belong to multiple hotels
- ✅ **Secure** - hotel creation only after verified login

## 🔧 Supabase Project Details
- Project ID: `hrlbtgpndjrnzvkaobmw`
- URL: `https://hrlbtgpndjrnzvkaobmw.supabase.co`
- Region: us-east-2




## 📝 Implementation Status

### ✅ Completed
- TODO.md updated with database trigger approach
- Database tables structure verified (all tables exist with proper foreign keys)

### 🚧 In Progress  
- Database trigger function creation
- iOS code updates to use metadata approach

### 📋 Next Steps
1. Clear existing auth data for clean slate
2. Create Postgres function + trigger for auto-profile creation
3. Update iOS code to pass metadata instead of manual profile creation
4. Test complete signup → verification → login flow

### 🎯 Expected Outcome
- No more "Failed to create profile" errors
- Profiles automatically created when user verifies email
- Signup data preserved in auth metadata
- Clean, reliable onboarding flow
