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
