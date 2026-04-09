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
