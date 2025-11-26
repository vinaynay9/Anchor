import Foundation

struct AppConfig {
    // MARK: - App Group
    static let appGroupIdentifier = "group.com.anchor.app"
    
    // MARK: - Backend
    static let apiBaseURL = "https://your-supabase-url.supabase.co"
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
    struct AppGroupKeys {
        static let sessionState = "sessionState"
        static let isSessionActive = "isSessionActive"
        static let sessionId = "sessionId"
        static let sessionMessage = "sessionMessage"
        static let timeRemaining = "timeRemaining"
    }
}

