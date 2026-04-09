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
