import Foundation
import Shared

struct AppConfig {
    // MARK: - App Group
    /// App Group identifier for shared storage between AnchorApp and Shield Extension.
    /// This should match AppGroupStorage.appGroupIdentifier for consistency.
    /// Use AppGroupStorage.appGroupIdentifier as the single source of truth.
    static let appGroupIdentifier = AppGroupStorage.appGroupIdentifier
    
    // MARK: - Backend
    static let apiBaseURL = "https://chkwsfgnvkmuvwtxfore.supabase.co"
    static let apiVersion = "v1"
    
    // MARK: - API Endpoints
    static var baseURL: URL {
        URL(string: "\(apiBaseURL)/rest/\(apiVersion)")!
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let currentUserId = "currentUserId"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }
    
    // MARK: - App Group Storage Keys
    // Note: AppGroupStorage now uses its own internal keys
    // Legacy keys removed - only SharedSessionState is used
}

