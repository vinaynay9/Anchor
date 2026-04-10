import Foundation
import Shared

// MARK: - RemoteConfigService
// AWS remote config endpoint removed. Remote config will be fetched from
// Supabase once connected (see SupabaseManager + SUPABASE_SETUP.md).
// For now this service returns the locally cached config if present.

final class RemoteConfigService {
    static let shared = RemoteConfigService()

    private let storage = AppGroupStorage.shared

    private init() {}

    var currentConfig: RemoteAppConfig? {
        storage.getRemoteAppConfig()
    }

    /// No-op until Supabase remote config is wired.
    /// TODO: [Supabase] fetch from supabase.from("remote_config").select().single()
    func refresh() async {
        // Remote config will come from Supabase once connected.
        // Cached config (if any) continues to be used.
    }
}

// MARK: - AnalyticsIngestService
// AWS Lambda analytics ingest removed.
// Analytics sync now goes through AggregateService → Supabase (see AggregateService.syncAggregates).

final class AnalyticsIngestService {
    static let shared = AnalyticsIngestService()
    private init() {}

    /// No-op — analytics now flow through AggregateService → Supabase daily_aggregates table.
    /// See AggregateService.syncAggregates() for the real implementation.
    func sendDailyProfileIfConfigured() async {
        // TODO: [Supabase] replaced by AggregateService.syncAggregates()
    }
}
import Foundation
import Supabase

// MARK: - SupabaseAuthService
// Handles sign-in with Apple and Google via Supabase OpenID Connect.
//
// Usage (called from AppCoordinator.handleSocialAuthSuccess):
//   let userId = try await SupabaseAuthService.shared.signIn(
//       idToken: credential.identityToken,
//       provider: .apple,
//       rawNonce: credential.rawNonce
//   )

enum SupabaseAuthError: Error, LocalizedError {
    case notConfigured
    case invalidToken
    case signInFailed(String)
    case signOutFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:         return "Supabase is not yet configured. See SUPABASE_SETUP.md."
        case .invalidToken:          return "Identity token could not be read."
        case .signInFailed(let msg): return "Sign-in failed: \(msg)"
        case .signOutFailed(let msg): return "Sign-out failed: \(msg)"
        }
    }
}

// MARK: - Provider enum (mirrors SocialAuthCredential.Provider without coupling)
enum SupabaseOAuthProvider {
    case apple, google
}

final class SupabaseAuthService {
    static let shared = SupabaseAuthService()
    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Sign In with ID Token (Apple / Google)

    /// Exchange a social ID token with Supabase.
    /// - Parameters:
    ///   - idToken: JWT identity token from Apple or Google
    ///   - provider: .apple or .google
    ///   - rawNonce: The un-hashed nonce originally passed to the Apple Sign-In request.
    ///               Required for Apple; pass nil for Google.
    /// - Returns: Supabase user ID (UUID string) on success
    func signIn(idToken: String, provider: SupabaseOAuthProvider, rawNonce: String?) async throws -> String {
        let credentials = OpenIDConnectCredentials(
            provider: provider == .apple ? .apple : .google,
            idToken: idToken,
            nonce: rawNonce
        )
        let session = try await client.auth.signInWithIdToken(credentials: credentials)
        return session.user.id.uuidString
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Current Session

    /// Returns the authenticated Supabase user ID if a valid session exists, or nil.
    func currentUserId() async -> String? {
        try? await client.auth.session.user.id.uuidString
    }
}
import Foundation

// MARK: - SupabaseUserService
// Manages the `users` table in Supabase.
// All methods are stubs until supabase-swift SPM package is added.
// See SUPABASE_SETUP.md for table schema and setup.

final class SupabaseUserService {
    static let shared = SupabaseUserService()
    private init() {}

    // MARK: - Upsert user profile after sign-in

    /// Creates or updates the user row in `users` table.
    /// Call this after Supabase auth succeeds.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("users")
    ///     .upsert([
    ///         "id": userId,
    ///         "email": email,
    ///         "display_name": displayName,
    ///         "updated_at": ISO8601DateFormatter().string(from: Date())
    ///     ], onConflict: "id")
    ///     .execute()
    /// ```
    func upsertProfile(userId: String, email: String, displayName: String?) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement upsert
    }

    // MARK: - Fetch user profile

    /// Fetches the user row for the given Supabase user ID.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// let rows: [[String: AnyJSON]] = try await SupabaseManager.shared.client
    ///     .from("users")
    ///     .select()
    ///     .eq("id", value: userId)
    ///     .single()
    ///     .execute()
    ///     .value
    /// ```
    func fetchProfile(userId: String) async throws -> [String: Any]? {
        guard SupabaseManager.shared.isConfigured else { return nil }
        // TODO: [Supabase] implement fetch
        return nil
    }

    // MARK: - Delete account

    /// Deletes the user row (hard delete). RLS ensures users can only delete their own row.
    /// Call this after confirming account deletion with the user.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("users")
    ///     .delete()
    ///     .eq("id", value: userId)
    ///     .execute()
    /// ```
    func deleteAccount(userId: String) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement delete
    }
}
import Foundation

// MARK: - SupabaseGoalService
// Manages the `habits` and `habit_categories` tables in Supabase.
// Goals are called "habits" in the DB schema.
// All methods are stubs until supabase-swift SPM package is added.

final class SupabaseGoalService {
    static let shared = SupabaseGoalService()
    private init() {}

    // MARK: - Sync goals to Supabase

    /// Upserts all local goals to the `habits` table.
    /// Call this after onboarding completes or when goals are added/edited.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// let rows = goals.map { goal in
    ///     [
    ///         "id": goal.id.uuidString,
    ///         "user_id": userId,
    ///         "title": goal.title,
    ///         "category": goal.category.rawValue,
    ///         "is_active": true,
    ///         "updated_at": ISO8601DateFormatter().string(from: Date())
    ///     ]
    /// }
    /// try await SupabaseManager.shared.client
    ///     .from("habits")
    ///     .upsert(rows, onConflict: "id")
    ///     .execute()
    /// ```
    func syncGoals(userId: String, goals: [[String: Any]]) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement sync
    }

    // MARK: - Fetch goals

    /// Fetches all active goals for a user from `habits` table.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// let rows: [[String: AnyJSON]] = try await SupabaseManager.shared.client
    ///     .from("habits")
    ///     .select()
    ///     .eq("user_id", value: userId)
    ///     .eq("is_active", value: true)
    ///     .execute()
    ///     .value
    /// ```
    func fetchGoals(userId: String) async throws -> [[String: Any]] {
        guard SupabaseManager.shared.isConfigured else { return [] }
        // TODO: [Supabase] implement fetch
        return []
    }

    // MARK: - Record goal completion

    /// Records a goal completion event in `events` table.
    /// category = "goal_completed", payload = { "habit_id": uuid }
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("events")
    ///     .insert([
    ///         "user_id": userId,
    ///         "category": "goal_completed",
    ///         "occurred_at": ISO8601DateFormatter().string(from: Date()),
    ///         "payload": ["habit_id": goalId]
    ///     ])
    ///     .execute()
    /// ```
    func recordGoalCompletion(userId: String, goalId: String) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement event insert
    }

    // MARK: - Delete goal

    /// Soft-deletes a goal by setting is_active = false.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("habits")
    ///     .update(["is_active": false, "updated_at": ISO8601DateFormatter().string(from: Date())])
    ///     .eq("id", value: goalId)
    ///     .execute()
    /// ```
    func deleteGoal(userId: String, goalId: String) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement soft delete
    }
}
import Foundation

// MARK: - SupabaseBlockingService
// Manages `blocking_preferences` and `reward_rules` tables in Supabase.
// All methods are stubs until supabase-swift SPM package is added.

final class SupabaseBlockingService {
    static let shared = SupabaseBlockingService()
    private init() {}

    // MARK: - Blocking Preferences

    /// Upserts blocking preferences (schedule + unlock policy) for a user.
    /// Stored as JSON-encoded data since app token sets are opaque types.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("blocking_preferences")
    ///     .upsert([
    ///         "user_id": userId,
    ///         "schedule_json": scheduleJSON,   // JSON string of LockSchedule
    ///         "policy_json": policyJSON,        // JSON string of UnlockPolicy
    ///         "updated_at": ISO8601DateFormatter().string(from: Date())
    ///     ], onConflict: "user_id")
    ///     .execute()
    /// ```
    func syncBlockingPreferences(userId: String, scheduleJSON: String, policyJSON: String) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement upsert
    }

    /// Fetches the user's blocking preferences.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// let row: [String: AnyJSON] = try await SupabaseManager.shared.client
    ///     .from("blocking_preferences")
    ///     .select()
    ///     .eq("user_id", value: userId)
    ///     .single()
    ///     .execute()
    ///     .value
    /// ```
    func fetchBlockingPreferences(userId: String) async throws -> (scheduleJSON: String, policyJSON: String)? {
        guard SupabaseManager.shared.isConfigured else { return nil }
        // TODO: [Supabase] implement fetch
        return nil
    }

    // MARK: - Reward Rules

    /// Upserts reward rules for a user.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("reward_rules")
    ///     .upsert([
    ///         "user_id": userId,
    ///         "rules_json": rulesJSON,
    ///         "updated_at": ISO8601DateFormatter().string(from: Date())
    ///     ], onConflict: "user_id")
    ///     .execute()
    /// ```
    func syncRewardRules(userId: String, rulesJSON: String) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement upsert
    }

    /// Fetches reward rules for a user.
    func fetchRewardRules(userId: String) async throws -> String? {
        guard SupabaseManager.shared.isConfigured else { return nil }
        // TODO: [Supabase] implement fetch
        return nil
    }
}
import Foundation

// MARK: - SupabaseEventsService
// Manages `events`, `emergency_unlocks`, and `errors` tables in Supabase.
// All methods are stubs until supabase-swift SPM package is added.

final class SupabaseEventsService {
    static let shared = SupabaseEventsService()
    private init() {}

    // MARK: - Generic Event Logging

    /// Logs a generic app event (shield_shown, goal_completed, session_started, etc.)
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("events")
    ///     .insert([
    ///         "user_id": userId,
    ///         "category": category,
    ///         "occurred_at": ISO8601DateFormatter().string(from: Date()),
    ///         "payload": payload   // [String: Any] dict
    ///     ])
    ///     .execute()
    /// ```
    func logEvent(userId: String, category: String, payload: [String: Any] = [:]) async {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement event insert
    }

    // MARK: - Emergency Unlocks

    /// Records an emergency unlock request in `emergency_unlocks` table.
    /// outcome: "approved" | "denied" | "pending"
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("emergency_unlocks")
    ///     .insert([
    ///         "user_id": userId,
    ///         "reason": reason,
    ///         "outcome": outcome,
    ///         "requested_at": ISO8601DateFormatter().string(from: Date())
    ///     ])
    ///     .execute()
    /// ```
    func recordEmergencyUnlock(userId: String, reason: String, outcome: String) async {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement insert
    }

    // MARK: - Error Reporting

    /// Logs a client-side error to `errors` table for remote diagnostics.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("errors")
    ///     .insert([
    ///         "user_id": userId,
    ///         "message": message,
    ///         "stack_trace": stackTrace ?? "",
    ///         "context": context,
    ///         "occurred_at": ISO8601DateFormatter().string(from: Date())
    ///     ])
    ///     .execute()
    /// ```
    func reportError(userId: String?, message: String, context: String, stackTrace: String? = nil) async {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement insert
    }
}
import Foundation

// MARK: - SupabaseAggregatesService
// Manages `daily_aggregates`, `weekly_aggregates`, and `monthly_aggregates` tables.
// All methods are stubs until supabase-swift SPM package is added.
// AggregateService.syncAggregates() calls this service.

final class SupabaseAggregatesService {
    static let shared = SupabaseAggregatesService()
    private init() {}

    // MARK: - Daily Aggregates

    /// Upserts daily aggregate rows for a user.
    /// aggregates: array of DailyAggregate encoded as [[String: Any]]
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// let rows = aggregates.map { agg in
    ///     [
    ///         "user_id": userId,
    ///         "date": agg.date,                          // "YYYY-MM-DD"
    ///         "locked_seconds": agg.lockedSeconds,
    ///         "goals_completed": agg.goalsCompleted,
    ///         "goals_total": agg.goalsTotal,
    ///         "shield_hits": agg.shieldHits,
    ///         "shield_hits_by_category": agg.shieldHitsByCategory  // JSON object
    ///     ]
    /// }
    /// try await SupabaseManager.shared.client
    ///     .from("daily_aggregates")
    ///     .upsert(rows, onConflict: "user_id,date")
    ///     .execute()
    /// ```
    func syncDailyAggregates(userId: String, aggregates: [DailyAggregate]) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement upsert
    }

    /// Fetches daily aggregates from Supabase for a date range.
    /// Useful when user installs app on a new device.
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// let rows: [[String: AnyJSON]] = try await SupabaseManager.shared.client
    ///     .from("daily_aggregates")
    ///     .select()
    ///     .eq("user_id", value: userId)
    ///     .gte("date", value: fromDate)   // "YYYY-MM-DD"
    ///     .order("date", ascending: true)
    ///     .execute()
    ///     .value
    /// ```
    func fetchDailyAggregates(userId: String, fromDate: String) async throws -> [DailyAggregate] {
        guard SupabaseManager.shared.isConfigured else { return [] }
        // TODO: [Supabase] implement fetch + decode into DailyAggregate
        return []
    }

    // MARK: - Weekly Aggregates

    /// Upserts a weekly rollup row.
    /// weekStart: "YYYY-MM-DD" (Monday of the week)
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("weekly_aggregates")
    ///     .upsert([
    ///         "user_id": userId,
    ///         "week_start": weekStart,
    ///         "total_locked_seconds": totalLockedSeconds,
    ///         "total_goals_completed": totalGoalsCompleted,
    ///         "total_shield_hits": totalShieldHits,
    ///         "days_complete": daysComplete   // days where all goals met
    ///     ], onConflict: "user_id,week_start")
    ///     .execute()
    /// ```
    func syncWeeklyAggregate(
        userId: String,
        weekStart: String,
        totalLockedSeconds: Int,
        totalGoalsCompleted: Int,
        totalShieldHits: Int,
        daysComplete: Int
    ) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement upsert
    }

    // MARK: - Monthly Aggregates

    /// Upserts a monthly rollup row.
    /// month: "YYYY-MM"
    ///
    /// TODO: [Supabase] Activate after SPM package is added:
    /// ```
    /// try await SupabaseManager.shared.client
    ///     .from("monthly_aggregates")
    ///     .upsert([
    ///         "user_id": userId,
    ///         "month": month,
    ///         "total_locked_seconds": totalLockedSeconds,
    ///         "total_goals_completed": totalGoalsCompleted,
    ///         "total_shield_hits": totalShieldHits,
    ///         "days_complete": daysComplete
    ///     ], onConflict: "user_id,month")
    ///     .execute()
    /// ```
    func syncMonthlyAggregate(
        userId: String,
        month: String,
        totalLockedSeconds: Int,
        totalGoalsCompleted: Int,
        totalShieldHits: Int,
        daysComplete: Int
    ) async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        // TODO: [Supabase] implement upsert
    }
}
