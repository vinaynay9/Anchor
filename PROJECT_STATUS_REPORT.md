# ANCHOR PROJECT STATUS REPORT
## Full Frontend + Backend Integration Analysis

---

## A. CORE LAYER

### A1. Models (Shared/Models/)

**Status: ✅ COMPLETE**

All models have proper Codable conformance with DTOs:

- **User.swift**: ✅ Complete with UserDTO
  - Properties: id, email, username, displayName, createdAt
  - DTO handles UUID ↔ String conversion
  - Date handling via ISO8601DateFormatter

- **Friend.swift**: ✅ Complete with FriendDTO
  - Properties: id, userId, friendId, friend (User?), status, createdAt
  - FriendshipStatus enum (pending, accepted, blocked)
  - DTO handles nested UserDTO conversion

- **LockSession.swift**: ✅ Complete with LockSessionDTO
  - Properties: id, userId, status, startTime, endTime, appsBlocked, accountabilityPartnerId, createdAt
  - SessionStatus enum (active, completed, cancelled)
  - DTO handles optional endTime and accountabilityPartnerId

- **UnlockRequest.swift**: ✅ Complete with UnlockRequestDTO
  - Properties: id, sessionId, requesterId, partnerId, status, message, createdAt, resolvedAt
  - UnlockRequestStatus enum (pending, approved, denied)
  - DTO handles optional message and resolvedAt

- **Proof.swift**: ✅ Complete with ProofDTO
  - Properties: id, sessionId, uploaderId, unlockRequestId, fileUrl, thumbnailUrl, createdAt
  - DTO handles URL string conversion and optional fields

**Issues Found:**
- None - all models are properly structured for JSON serialization/deserialization

---

### A2. Networking

#### Endpoint.swift
**Status: ✅ ALL ENDPOINTS DEFINED**

All required endpoints are present:
- ✅ POST /auth/apple
- ✅ GET /user/me
- ✅ PATCH /user/me
- ✅ GET /friends
- ✅ POST /friends
- ✅ DELETE /friends/{id}
- ✅ GET /friends/requests
- ✅ POST /friends/requests/{id}/accept
- ✅ POST /friends/requests/{id}/reject
- ✅ POST /sessions/start
- ✅ POST /sessions/end
- ✅ GET /sessions/active
- ✅ POST /unlock-requests
- ✅ GET /unlock-requests/pending
- ✅ POST /unlock-requests/{id}/approve
- ✅ POST /unlock-requests/{id}/reject
- ✅ POST /proofs (multipart)
- ✅ GET /proofs/{id}
- ✅ GET /proofs/user/{id}
- ✅ POST /notifications/device-token

**Issues Found:**
- None - all endpoints correctly defined with proper HTTP methods

#### APIClient.swift
**Status: ✅ COMPLETE**

- ✅ Uses async/await
- ✅ Handles decoding errors (APIError.decodingError)
- ✅ Handles network errors (APIError.networkError)
- ✅ Validates status codes (200-299)
- ✅ Handles 401 unauthorized
- ✅ Supports query strings in paths
- ✅ Properly sets headers including Authorization bearer token
- ✅ ISO8601 date decoding strategy

**Issues Found:**
- None - APIClient is production-ready

#### SupabaseClient.swift
**Status: ⚠️ PLACEHOLDER**

- Currently just a wrapper around APIClient
- Provides token management (setAuthToken, clearAuthToken)
- Does NOT conflict with APIClient - it's a complementary layer
- TODO: Can be extended with Supabase Swift SDK later

**Issues Found:**
- None - this is intentional as a placeholder

---

### A3. Services

#### AuthService
**Status: ⚠️ PARTIALLY IMPLEMENTED**

**Public Functions:**
- `signInWithApple()` - ✅ Calls POST /auth/apple, but uses placeholder token
- `signInWithGoogle()` - ❌ Mock implementation, doesn't call API
- `signOut()` - ⚠️ Clears local storage but doesn't call backend
- `currentUser()` - ✅ Calls GET /user/me

**Issues Found:**
- `signInWithApple()` uses "placeholder_token" - needs real token integration (TODO)
- `signInWithGoogle()` is completely mocked - needs endpoint definition
- `signOut()` should call backend to invalidate token (TODO)

#### UserService
**Status: ✅ COMPLETE**

**Public Functions:**
- `getCurrentUser()` - ✅ Calls GET /user/me
- `getUser(id:)` - ⚠️ Falls back to getCurrentUser (no separate endpoint)
- `updateUser(username:displayName:)` - ✅ Calls PATCH /user/me
- `searchUsers(query:)` - ❌ Returns empty array (TODO)

**Issues Found:**
- `searchUsers()` not implemented - endpoint may not exist yet

#### FriendService
**Status: ✅ COMPLETE**

**Public Functions:**
- `getFriends()` - ✅ Calls GET /friends
- `addFriend(friendId:)` - ✅ Calls POST /friends
- `deleteFriend(id:)` - ✅ Calls DELETE /friends/{id}
- `getFriendRequests()` - ✅ Calls GET /friends/requests
- `acceptFriendRequest(id:)` - ✅ Calls POST /friends/requests/{id}/accept
- `rejectFriendRequest(id:)` - ✅ Calls POST /friends/requests/{id}/reject

**Issues Found:**
- None - all endpoints properly implemented

#### SessionService
**Status: ✅ COMPLETE**

**Public Functions:**
- `startSession(durationMinutes:friendIds:)` - ✅ Calls POST /sessions/start
- `endSession()` - ✅ Calls POST /sessions/end
- `getActiveSession()` - ✅ Calls GET /sessions/active

**Issues Found:**
- Uses real ScreenTimeService.shared - needs to be protocol-based for mocking
- Timer management is local (good)
- AppGroupStorage integration is correct

#### UnlockRequestService
**Status: ✅ COMPLETE**

**Public Functions:**
- `sendUnlockRequest(sessionId:reason:)` - ✅ Calls POST /unlock-requests
- `cancelUnlockRequest(sessionId:)` - ⚠️ Only updates local state (no backend call)
- `getPendingUnlockRequests()` - ✅ Calls GET /unlock-requests/pending
- `approveUnlockRequest(requestId:)` - ✅ Calls POST /unlock-requests/{id}/approve
- `denyUnlockRequest(requestId:)` - ✅ Calls POST /unlock-requests/{id}/reject

**Issues Found:**
- `cancelUnlockRequest()` doesn't call backend (may not have endpoint)

#### ProofService
**Status: ⚠️ MISSING PROTOCOL**

**Public Functions:**
- `uploadProof(sessionId:image:)` - ✅ Calls POST /proofs (multipart)
- `getProof(id:)` - ✅ Calls GET /proofs/{id}
- `getProofsForUser(userId:)` - ✅ Calls GET /proofs/user/{id}

**Issues Found:**
- ❌ No `ProofServiceProtocol` defined, but ProofViewModel expects it
- Method signature mismatch: ViewModel calls `fetchProofs(for:)` and `uploadProof(imageData:sessionId:)` but service has different signatures

#### NotificationService
**Status: ⚠️ PARTIALLY IMPLEMENTED**

**Public Functions:**
- `requestAuthorization()` - ✅ Requests UNUserNotificationCenter authorization
- `registerForPushNotifications()` - ❌ Throws error (TODO)
- `handleNotification(_:)` - ✅ Basic handler
- `scheduleLocalNotification(...)` - ✅ Works
- `registerDeviceToken(_:)` - ✅ Calls POST /notifications/device-token

**Issues Found:**
- `registerForPushNotifications()` needs APNs integration (device-only, TODO)

#### ScreenTimeService
**Status: ❌ USES REAL SCREEN TIME (WON'T WORK IN SIMULATOR)**

**Public Functions:**
- `requestAuthorization()` - Uses real AuthorizationCenter
- `isAuthorized()` - Uses real AuthorizationCenter
- `selectApps()` - Uses real FamilyActivitySelection
- `activateShields(...)` - Uses real ManagedSettingsStore
- `deactivateShields()` - Uses real ManagedSettingsStore
- `startBlocking(for:)` - Uses real ManagedSettingsStore
- `stopBlocking()` - Uses real ManagedSettingsStore

**Issues Found:**
- ❌ Uses real FamilyControls/ManagedSettings - will fail in simulator
- ❌ No protocol abstraction - can't inject mock
- ❌ SessionService directly uses ScreenTimeService.shared (hard dependency)

#### ActivitySelectionService
**Status: ✅ COMPLETE**

**Public Functions:**
- `saveSelection(_:)` - ✅ Saves to AppGroupStorage
- `loadSelection()` - ✅ Loads from AppGroupStorage
- `loadApplicationTokens()` - ✅ Extracts tokens from selection
- `clearSelection()` - ✅ Clears storage

**Issues Found:**
- Uses real FamilyActivitySelection (but this is just data storage, OK)

---

## B. FEATURE LAYER

### B1. Auth Feature

**ViewModel: AuthViewModel**
- ✅ `@Published currentUser: User?`
- ✅ `@Published isLoading: Bool`
- ✅ `@Published errorMessage: String?`
- ✅ `@Published needsUsernameSetup: Bool`
- ✅ `loadCurrentUser()` - Calls AuthService.currentUser()
- ✅ `signInWithApple()` - Calls AuthService.signInWithApple()
- ✅ `signInWithGoogle()` - Calls AuthService.signInWithGoogle()
- ✅ `completeUsernameSetup(_:)` - Calls UserService.updateUser()

**Issues Found:**
- ❌ Missing `import Shared` (User type not imported)
- ❌ RootView references `authViewModel.authState` which doesn't exist

**Views:**
- ✅ AuthRootView - Uses AuthViewModel
- ✅ SignInOptionsView - Exists
- ✅ UsernameSetupView - Exists

---

### B2. Friends Feature

**ViewModel: FriendsViewModel**
- ✅ `@Published friends: [Friend]`
- ✅ `@Published pendingRequests: [Friend]`
- ✅ `@Published isLoading: Bool`
- ✅ `@Published errorMessage: String?`
- ✅ `loadFriends()` - Calls FriendService.getFriends()
- ✅ `loadPendingRequests()` - Calls FriendService.getFriendRequests()
- ✅ `sendFriendRequest(friendId:)` - Calls FriendService.addFriend()
- ✅ `acceptFriendRequest(requestId:)` - Calls FriendService.acceptFriendRequest()

**Issues Found:**
- ✅ Missing `rejectFriendRequest()` method in ViewModel

**Views:**
- ✅ FriendsListView - Uses FriendsViewModel
- ✅ AddFriendView - Uses FriendsViewModel
- ✅ FriendSearchView - Exists
- ✅ PendingRequestsView - Uses FriendsViewModel

---

### B3. Sessions Feature

**ViewModel: SessionViewModel**
- ✅ `@Published activeSession: LockSession?`
- ✅ `@Published isLoading: Bool`
- ✅ `@Published errorMessage: String?`
- ✅ `@Published selectedDurationMinutes: Int`
- ✅ `@Published selectedFriendIds: [String]`
- ✅ `loadActiveSession()` - Calls SessionService.getActiveSession()
- ✅ `startSession()` - Calls SessionService.startSession()
- ✅ `endSession()` - Calls SessionService.endSession()

**Issues Found:**
- ⚠️ Directly uses ScreenTimeService.shared (hard dependency)
- ✅ Uses protocol injection for SessionService (good)

**Views:**
- ✅ SessionHomeView - Uses SessionViewModel
- ✅ SessionSetupView - Uses SessionViewModel
- ✅ ActiveSessionView - Uses SessionViewModel
- ✅ ActivityPickerView - Exists

---

### B4. UnlockRequests Feature

**ViewModel: UnlockRequestsViewModel**
- ✅ `@Published pendingRequests: [UnlockRequest]`
- ✅ `@Published isLoading: Bool`
- ✅ `@Published errorMessage: String?`
- ❌ `loadPendingRequests()` - Has TODO, doesn't call service
- ❌ `approveRequest(_:)` - Has TODO, doesn't call service
- ❌ `denyRequest(_:)` - Has TODO, doesn't call service

**Issues Found:**
- ❌ Not wired to UnlockRequestService
- ❌ Uses APIClient directly instead of service
- ❌ Methods have TODOs instead of real implementation

**Views:**
- ✅ IncomingRequestsListView - Uses UnlockRequestsViewModel
- ✅ UnlockRequestDetailView - Exists

---

### B5. Proofs Feature

**ViewModel: ProofViewModel**
- ✅ `@Published proofs: [Proof]`
- ✅ `@Published isUploading: Bool`
- ✅ `@Published isLoading: Bool`
- ✅ `@Published errorMessage: String?`
- ❌ `loadProofs(for:)` - Calls `proofService.fetchProofs(for:)` which doesn't exist
- ❌ `upload(image:for:)` - Calls `proofService.uploadProof(imageData:sessionId:)` with wrong signature

**Issues Found:**
- ❌ ProofServiceProtocol not defined
- ❌ Method signature mismatches between ViewModel and Service
- ❌ Service has `uploadProof(sessionId:image:)` but ViewModel calls `uploadProof(imageData:sessionId:)`
- ❌ Service has `getProofsForUser(userId:)` but ViewModel calls `fetchProofs(for:)`

**Views:**
- ✅ ProofGalleryView - Uses ProofViewModel
- ✅ CaptureProofView - Uses ProofViewModel

---

### B6. Settings Feature

**ViewModel: SettingsViewModel**
- ✅ `@Published currentUser: User?`
- ✅ `@Published isLoading: Bool`
- ✅ `loadCurrentUser()` - Calls UserService.getCurrentUser()
- ✅ `signOut()` - Calls AuthService.signOut()

**Issues Found:**
- ❌ Missing `import Shared` (User type not imported)
- ⚠️ No Screen Time permission state (should use ScreenTimeServiceProtocol)

**Views:**
- ✅ SettingsView - Exists
- ✅ NotificationSettingsView - Exists
- ✅ ScreenTimePermissionView - Exists

---

### B7. Root Feature

**RootView:**
- ❌ References `authViewModel.authState` which doesn't exist
- Should check `authViewModel.currentUser` instead

**MainTabView:**
- ✅ Has 4 tabs: Sessions, Friends, Requests, Settings
- ✅ Navigation structure is correct

**Issues Found:**
- RootView logic needs fixing

---

## C. SHIELD EXTENSION

**Status: ✅ STRUCTURE COMPLETE**

- ✅ ShieldExtension.swift - Entry point exists
- ✅ ShieldView.swift - UI exists
- ✅ ShieldViewModel.swift - Logic exists
- ✅ ShieldDesignSystem.swift - Design system exists
- ✅ Uses Shared module (AppGroupStorage, SharedSessionState)

**Issues Found:**
- ✅ AppGroupStorage integration is correct
- ✅ SharedSessionState model is in Shared module
- ⚠️ ShieldView references ShieldColors/ShieldTypography which should be in ShieldDesignSystem (need to verify)

---

## D. UTILITIES/DESIGN SYSTEM

**Status: ✅ COMPLETE**

- ✅ AppColors - Defined in Colors/AppColors.swift
- ✅ AppTypography - Defined in Typography/AppTypography.swift
- ✅ AppButtonStyle - Defined in Components/AppButtonStyle.swift (PrimaryButtonStyle, SecondaryButtonStyle, DangerButtonStyle)
- ✅ AppTextFieldStyle - Defined in Components/AppTextFieldStyle.swift
- ✅ Theme - Defined in Theme.swift

**Issues Found:**
- ✅ Design system is well-organized
- ✅ Consistent usage across features

---

## SUMMARY OF CRITICAL ISSUES

### 🔴 CRITICAL (Must Fix)
1. **ProofServiceProtocol missing** - ProofViewModel expects protocol that doesn't exist
2. **ProofService method signature mismatches** - ViewModel calls methods that don't match service
3. **UnlockRequestsViewModel not wired** - Has TODOs instead of real service calls
4. **RootView references non-existent authState** - Should use currentUser check
5. **ScreenTimeService hard dependency** - No protocol, can't mock for simulator
6. **Missing MockScreenTimeService** - Required for simulator testing

### 🟡 MEDIUM (Should Fix)
7. **AuthViewModel missing import Shared** - User type not imported
8. **SettingsViewModel missing import Shared** - User type not imported
9. **FriendsViewModel missing rejectFriendRequest()** - Method exists in service but not ViewModel
10. **AuthService.signInWithApple() uses placeholder token** - Needs real token (but can be TODO for now)

### 🟢 LOW (Nice to Have)
11. **UserService.searchUsers() not implemented** - May not have endpoint yet
12. **UnlockRequestService.cancelUnlockRequest() doesn't call backend** - May not have endpoint
13. **NotificationService.registerForPushNotifications() throws error** - Device-only, can be TODO

---

## IMPLEMENTATION PLAN

### Phase 1: Fix Critical Issues
1. Create ProofServiceProtocol and fix method signatures
2. Wire UnlockRequestsViewModel to UnlockRequestService
3. Fix RootView authState reference
4. Create ScreenTimeServiceProtocol and MockScreenTimeService
5. Fix import statements

### Phase 2: Complete Service Integration
6. Add missing ViewModel methods
7. Ensure all ViewModels use services correctly

### Phase 3: Testing & Polish
8. Verify all endpoints are called correctly
9. Test error handling
10. Verify navigation flows

