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
