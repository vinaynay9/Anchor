# Supabase Setup Guide — Anchor

This document covers everything needed to connect Anchor to a Supabase project:
SQL schema, RLS policies, auth provider configuration, and Xcode project setup.

---

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project.
2. Note your **Project URL** and **anon (public) key** from
   Settings → API → Project API keys.

---

## 2. SQL Schema

Run all of the following in Supabase → SQL Editor.

```sql
-- ────────────────────────────────────────────
-- USERS
-- ────────────────────────────────────────────
create table if not exists public.users (
    id              uuid primary key references auth.users(id) on delete cascade,
    email           text,
    display_name    text,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

alter table public.users enable row level security;

create policy "Users can read their own row"
    on public.users for select
    using (auth.uid() = id);

create policy "Users can update their own row"
    on public.users for update
    using (auth.uid() = id);

create policy "Users can insert their own row"
    on public.users for insert
    with check (auth.uid() = id);

create policy "Users can delete their own row"
    on public.users for delete
    using (auth.uid() = id);


-- ────────────────────────────────────────────
-- HABITS (Goals)
-- ────────────────────────────────────────────
create table if not exists public.habits (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references public.users(id) on delete cascade,
    title       text not null,
    category    text not null default 'other',
    is_active   boolean not null default true,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

alter table public.habits enable row level security;

create policy "Users manage their own habits"
    on public.habits for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- BLOCKING PREFERENCES
-- ────────────────────────────────────────────
create table if not exists public.blocking_preferences (
    user_id         uuid primary key references public.users(id) on delete cascade,
    schedule_json   text,    -- JSON-encoded lock schedule
    policy_json     text,    -- JSON-encoded unlock policy
    updated_at      timestamptz not null default now()
);

alter table public.blocking_preferences enable row level security;

create policy "Users manage their own blocking prefs"
    on public.blocking_preferences for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- REWARD RULES
-- ────────────────────────────────────────────
create table if not exists public.reward_rules (
    user_id     uuid primary key references public.users(id) on delete cascade,
    rules_json  text,    -- JSON-encoded array of RewardRule
    updated_at  timestamptz not null default now()
);

alter table public.reward_rules enable row level security;

create policy "Users manage their own reward rules"
    on public.reward_rules for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- EVENTS
-- ────────────────────────────────────────────
create table if not exists public.events (
    id              bigserial primary key,
    user_id         uuid not null references public.users(id) on delete cascade,
    category        text not null,   -- e.g. "shield_shown", "goal_completed", "session_started"
    occurred_at     timestamptz not null default now(),
    payload         jsonb
);

alter table public.events enable row level security;

create policy "Users manage their own events"
    on public.events for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- EMERGENCY UNLOCKS
-- ────────────────────────────────────────────
create table if not exists public.emergency_unlocks (
    id              bigserial primary key,
    user_id         uuid not null references public.users(id) on delete cascade,
    reason          text,
    outcome         text not null default 'pending',  -- "approved" | "denied" | "pending"
    requested_at    timestamptz not null default now()
);

alter table public.emergency_unlocks enable row level security;

create policy "Users manage their own emergency unlocks"
    on public.emergency_unlocks for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- ERRORS
-- ────────────────────────────────────────────
create table if not exists public.errors (
    id              bigserial primary key,
    user_id         uuid references public.users(id) on delete set null,
    message         text not null,
    stack_trace     text,
    context         text,
    occurred_at     timestamptz not null default now()
);

alter table public.errors enable row level security;

create policy "Users can insert their own errors"
    on public.errors for insert
    with check (auth.uid() = user_id or user_id is null);

create policy "Users can read their own errors"
    on public.errors for select
    using (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- DAILY AGGREGATES
-- ────────────────────────────────────────────
create table if not exists public.daily_aggregates (
    user_id                     uuid not null references public.users(id) on delete cascade,
    date                        date not null,  -- "YYYY-MM-DD"
    locked_seconds              int not null default 0,
    goals_completed             int not null default 0,
    goals_total                 int not null default 0,
    shield_hits                 int not null default 0,
    shield_hits_by_category     jsonb,          -- { "social": 3, "games": 1, ... }
    primary key (user_id, date)
);

alter table public.daily_aggregates enable row level security;

create policy "Users manage their own daily aggregates"
    on public.daily_aggregates for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- WEEKLY AGGREGATES
-- ────────────────────────────────────────────
create table if not exists public.weekly_aggregates (
    user_id                 uuid not null references public.users(id) on delete cascade,
    week_start              date not null,   -- Monday of the week
    total_locked_seconds    int not null default 0,
    total_goals_completed   int not null default 0,
    total_shield_hits       int not null default 0,
    days_complete           int not null default 0,
    primary key (user_id, week_start)
);

alter table public.weekly_aggregates enable row level security;

create policy "Users manage their own weekly aggregates"
    on public.weekly_aggregates for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- MONTHLY AGGREGATES
-- ────────────────────────────────────────────
create table if not exists public.monthly_aggregates (
    user_id                 uuid not null references public.users(id) on delete cascade,
    month                   text not null,   -- "YYYY-MM"
    total_locked_seconds    int not null default 0,
    total_goals_completed   int not null default 0,
    total_shield_hits       int not null default 0,
    days_complete           int not null default 0,
    primary key (user_id, month)
);

alter table public.monthly_aggregates enable row level security;

create policy "Users manage their own monthly aggregates"
    on public.monthly_aggregates for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
```

---

## 3. Auth Provider Setup

### Apple Sign-In

1. Supabase dashboard → Authentication → Providers → Apple.
2. Enable Apple provider.
3. Enter your **Services ID** (e.g. `com.vinay.anchor.signin`).
4. Enter your **Team ID**, **Key ID**, and **private key** (.p8 file contents).
5. Redirect URL to add in Apple Developer Console:
   `https://<your-project-ref>.supabase.co/auth/v1/callback`

### Google Sign-In

1. Supabase dashboard → Authentication → Providers → Google.
2. Enable Google provider.
3. Enter your **OAuth 2.0 Client ID** (Web Application type from Google Cloud Console).
4. Enter your **Client Secret**.
5. Add the Supabase callback URL as an authorised redirect URI in Google Cloud:
   `https://<your-project-ref>.supabase.co/auth/v1/callback`
6. Also add your iOS client ID to `Info.plist → GOOGLE_CLIENT_ID`
   (already wired — just replace `REPLACE_ME` with your actual iOS client ID).

---

## 4. Xcode Configuration

### Step 1 — Add supabase-swift SPM package

In Xcode: File → Add Package Dependencies
URL: `https://github.com/supabase/supabase-swift`
Version: `2.x` (latest stable)
Add to target: **AnchorApp**

### Step 2 — Create Anchor.xcconfig

Create `AnchorApp/Anchor.xcconfig` (do NOT commit this file — add to `.gitignore`):

```
SUPABASE_URL = https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY = YOUR_ANON_KEY_HERE
```

### Step 3 — Set build configuration to use .xcconfig

In Xcode: Project → Info → Configurations
For both **Debug** and **Release**, set the configuration file for **AnchorApp** target to `Anchor.xcconfig`.

### Step 4 — Verify Info.plist keys

`AnchorApp/Info.plist` already contains:
```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

### Step 5 — Activate SupabaseManager

In `AnchorApp/Core/Networking/SupabaseManager.swift`:
1. Uncomment `import Supabase`
2. Uncomment `let client: SupabaseClient`
3. Replace the entire class body with the "Real Implementation" block already in the file (commented at the bottom)

### Step 6 — Activate SupabaseAuthService

In `AnchorApp/Core/Services/Supabase/SupabaseAuthService.swift`:
- Uncomment the `import Supabase` line
- Replace each stub method body with the commented-out real implementation

### Step 7 — Add new files to Xcode project

The following files were created on disk and need to be added in Xcode
(drag into the project navigator or use "Add Files to project"):

- `AnchorApp/Core/Networking/SupabaseManager.swift`
- `AnchorApp/Core/Services/Supabase/SupabaseAuthService.swift`
- `AnchorApp/Core/Services/Supabase/SupabaseUserService.swift`
- `AnchorApp/Core/Services/Supabase/SupabaseGoalService.swift`
- `AnchorApp/Core/Services/Supabase/SupabaseBlockingService.swift`
- `AnchorApp/Core/Services/Supabase/SupabaseEventsService.swift`
- `AnchorApp/Core/Services/Supabase/SupabaseAggregatesService.swift`

---

## 5. .gitignore

Add the following to `.gitignore` to prevent committing secrets:

```
AnchorApp/Anchor.xcconfig
*.xcconfig
```

---

## 6. Testing the connection

After completing setup, add a quick test to `AppCoordinator` or a debug view:

```swift
// Verify Supabase is reachable
if SupabaseManager.shared.isConfigured {
    print("✅ Supabase configured")
} else {
    print("❌ Supabase not configured — check .xcconfig")
}
```

On first sign-in, `AppCoordinator.handleSocialAuthSuccess` will call
`SupabaseAuthService.shared.signIn(idToken:provider:rawNonce:)` and log the result.

---

## 7. Data flow summary

```
User signs in (Apple/Google)
  → SocialAuthViewModel: generates nonce, exchanges with provider
  → AppCoordinator.handleSocialAuthSuccess(credential)
      → SupabaseAuthService.signIn(idToken:provider:rawNonce:)
          → supabase.auth.signInWithIdToken(OpenIDConnectCredentials)
          → returns Supabase user UUID
      → SupabaseUserService.upsertProfile(userId:email:displayName:)
          → upserts row in public.users
      → routeAfterSocialAuth() → onboarding or main tab

After onboarding:
  → SupabaseGoalService.syncGoals(userId:goals:)         → public.habits
  → SupabaseBlockingService.syncBlockingPreferences(...)  → public.blocking_preferences
  → SupabaseBlockingService.syncRewardRules(...)          → public.reward_rules

Daily (on background / app resign active):
  → AggregateService.recordTodaySnapshot()
  → AggregateService.syncAggregates()
      → SupabaseAggregatesService.syncDailyAggregates(...)  → public.daily_aggregates

Events (shield hits, goal completions):
  → SupabaseEventsService.logEvent(userId:category:payload:)  → public.events
```
