import Foundation
import Shared

struct AppConfig {
    // MARK: - App Group
    /// Single source of truth for App Group identifier.
    static let appGroupIdentifier = AppGroupStorage.appGroupIdentifier

    // MARK: - Invites
    static let inviteBaseURL = URL(string: "https://anchor.app/invite")!

    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let currentUserId      = "currentUserId"
        static let accessToken        = "accessToken"
        static let refreshToken       = "refreshToken"
        static let hasSeenOnboarding  = "hasSeenOnboarding"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
}

// NOTE: AWS API Gateway (apiBaseURL, analyticsIngestURL, analyticsIngestApiKey) removed.
// All backend calls now go through SupabaseManager. See SUPABASE_SETUP.md.
