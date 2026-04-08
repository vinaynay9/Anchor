# Anchor Auth Setup Guide

Anchor uses **Sign in with Apple** and **Google Sign-In** exclusively.
All API keys live in `AnchorApp/Info.plist` — zero code changes are needed for keys.

---

## 1 · Sign in with Apple

### What you need
Apple Sign In is tied to your Apple Developer account and Bundle ID.
No external API keys are required.

### Xcode setup (one-time)
1. Open `Anchor.xcodeproj` in Xcode.
2. Select the **AnchorApp** target → **Signing & Capabilities** tab.
3. Click **+** and add the **Sign In with Apple** capability.
4. That's it — no Info.plist entries needed.

### Info.plist keys
None.

---

## 2 · Google Sign-In

### Step 1 — Create / locate your Google project
1. Go to [console.firebase.google.com](https://console.firebase.google.com) **or** [console.cloud.google.com](https://console.cloud.google.com).
2. Create (or select) the project you want to use for Anchor.

### Step 2 — Enable Google Sign-In
- **Firebase path:** Authentication → Sign-in method → Google → Enable.
- **GCP-only path:** APIs & Services → OAuth consent screen → configure, then create credentials below.

### Step 3 — Create an iOS OAuth client ID
1. GCP Console → **APIs & Services → Credentials → + Create Credentials → OAuth client ID**.
2. Application type: **iOS**.
3. Bundle ID: your app's Bundle ID (e.g., `com.anchor.app`).
4. Click **Create**.
5. Copy the generated **Client ID** — it looks like:
   `123456789-abcdef.apps.googleusercontent.com`

### Step 4 — Add keys to Info.plist

Open `AnchorApp/Info.plist` and update these two values:

| Key | Where in plist | Value |
|-----|---------------|-------|
| `GOOGLE_CLIENT_ID` | Top-level string | Your iOS Client ID, e.g. `123456789-abcdef.apps.googleusercontent.com` |
| `REVERSED_GOOGLE_CLIENT_ID` (in `CFBundleURLSchemes`) | The second URL type entry | Reversed Client ID, e.g. `com.googleusercontent.apps.123456789-abcdef` |

**How to reverse the Client ID:**
Take `123456789-abcdef.apps.googleusercontent.com` and reverse the domain segments:
→ `com.googleusercontent.apps.123456789-abcdef`

### Step 5 — Add the SPM package
1. Xcode → **File → Add Package Dependencies…**
2. Paste the URL: `https://github.com/google/GoogleSignIn-iOS`
3. Minimum version: **7.0.0** (recommended: latest 8.x).
4. When prompted, add the **`GoogleSignIn`** library to the **AnchorApp** target only
   (not to AnchorShieldExtension or Shared).

---

## 3 · Files to add to Xcode

After creating these files, add them to the **AnchorApp** target in Xcode
(**File → Add Files to "AnchorApp"**, or drag into the Project Navigator):

### New files
| File | Group |
|------|-------|
| `AnchorApp/Features/Auth/Models/SocialAuthCredential.swift` | Auth/Models |
| `AnchorApp/Features/Auth/ViewModels/SocialAuthViewModel.swift` | Auth/ViewModels |
| `AnchorApp/Features/Auth/Views/SocialAuthView.swift` | Auth/Views |
| `AnchorApp/Features/Auth/Views/ProfileSetupView.swift` | Auth/Views |

### Modified files (already in Xcode — no re-adding needed)
- `AnchorApp/Navigation/AppCoordinator.swift`
- `AnchorApp/Navigation/AuthFlow.swift`
- `AnchorApp/AnchorAppApp.swift`
- `AnchorApp/Info.plist`

---

## 4 · Files to remove from Xcode (email auth — now deleted)

These files implemented email/password auth and are no longer needed.
Delete them from the Xcode target **and** the filesystem:

| File |
|------|
| `AnchorApp/Features/Auth/Views/EmailSignInView.swift` |
| `AnchorApp/Features/Auth/Views/EmailSignUpView.swift` |
| `AnchorApp/Features/Auth/Views/SignInOptionsView.swift` |
| `AnchorApp/Features/Auth/Views/UsernameSetupView.swift` |
| `AnchorApp/Features/Auth/ViewModels/EmailAuthViewModel.swift` |
| `AnchorApp/Features/Onboarding/Views/PersonalInfoView.swift` ← replaced by `ProfileSetupView` |

---

## 5 · Auth → Profile flow summary

```
Onboarding pager → Get Started
    ↓
SocialAuthView  (Apple or Google sign-in)
    ↓ credential delivered to AppCoordinator
ProfileSetupView  (first name, last name, birthday — pre-filled from provider)
    ↓ saves to AppGroupStorage + best-effort backend sync
PostAuthOnboardingFlowView  (goals → unlock rules → app selection)
    ↓
MainTabView
```

---

## 6 · Supabase migration TODOs

Once the Supabase client is wired up, search for `// TODO: [Supabase Migration]` in the
codebase.  The two key integration points are:

1. **`AppCoordinator.handleSocialAuthSuccess`** — exchange the identity token:
   ```swift
   // provider: .apple → OpenIDConnectCredentials(provider: .apple, idToken:, nonce:)
   // provider: .google → OpenIDConnectCredentials(provider: .google, idToken:)
   let session = try await SupabaseClient.shared.auth.signInWithIdToken(credentials: ...)
   authViewModel.handleAuthenticatedUser(session.user.toAnchorUser())
   ```

2. **`ProfileSetupViewModel.save`** — upsert profile row:
   ```swift
   try await SupabaseClient.shared.from("users").upsert([...]).execute()
   ```

After the migration, the `hasCachedUserId` fallback in `AppCoordinator.determineInitialFlow`
can be removed; `authViewModel.currentUser` will always be non-nil for authenticated users.
