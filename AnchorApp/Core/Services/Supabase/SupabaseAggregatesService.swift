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
