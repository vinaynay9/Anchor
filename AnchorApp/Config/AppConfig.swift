import Foundation
import Shared

struct AppConfig {
    // MARK: - App Group
    /// App Group identifier for shared storage between AnchorApp and Shield Extension.
    /// This should match AppGroupStorage.appGroupIdentifier for consistency.
    /// Use AppGroupStorage.appGroupIdentifier as the single source of truth.
    static let appGroupIdentifier = AppGroupStorage.appGroupIdentifier
    
    // MARK: - Backend
    static let apiBaseURL = Secrets.apiBaseURL
    static let apiVersion = "v1"
    static let analyticsIngestApiKey = ProcessInfo.processInfo.environment["ANCHOR_INGEST_API_KEY"] ?? ""
    
    // MARK: - Invites
    static let inviteBaseURL = URL(string: "https://anchor.app/invite")!

    static var analyticsIngestURL: URL? {
        let trimmed = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed != "REPLACE_ME",
              trimmed != "https://REPLACE_ME" else {
            return nil
        }
        return URL(string: "\(trimmed)/v0/metrics/daily")
    }
    
    // MARK: - API Endpoints
    static var baseURL: URL {
        let trimmed = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "http://localhost"
        let base = (trimmed.isEmpty || trimmed == "REPLACE_ME" || trimmed == "https://REPLACE_ME") ? fallback : trimmed
        // If apiBaseURL is already a full base (e.g. API Gateway /v0), use it directly.
        if base.contains("/v0") || base.contains("execute-api") {
            return URL(string: base) ?? URL(string: fallback)!
        }
        if let url = URL(string: "\(base)/rest/\(apiVersion)") {
            return url
        }
        return URL(string: "http://localhost/rest/\(apiVersion)") ?? URL(string: "http://localhost")!
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let currentUserId = "currentUserId"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
    
    // MARK: - App Group Storage Keys
    // Note: AppGroupStorage now uses its own internal keys
    // Legacy keys removed - only SharedSessionState is used
}
