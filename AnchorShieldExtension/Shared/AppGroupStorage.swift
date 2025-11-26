import Foundation

// MARK: - Shared Session State (for Shield Extension)
struct SessionState: Codable {
    let isActive: Bool
    let sessionId: UUID?
    let message: String?
    let timeRemaining: TimeInterval?
    
    static let empty = SessionState(
        isActive: false,
        sessionId: nil,
        message: nil,
        timeRemaining: nil
    )
}

// MARK: - App Group Storage Keys
struct AppGroupKeys {
    static let isSessionActive = "isSessionActive"
    static let sessionId = "sessionId"
    static let sessionMessage = "sessionMessage"
    static let timeRemaining = "timeRemaining"
}

// MARK: - App Group Storage Service (for Shield Extension)
class AppGroupStorage {
    static let shared = AppGroupStorage()
    
    // NOTE: This must match the app group identifier in the main app's AppConfig
    private let appGroupIdentifier = "group.com.anchor.app"
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Session State
    func getSessionState() -> SessionState {
        guard let defaults = userDefaults else { return .empty }
        
        let isActive = defaults.bool(forKey: AppGroupKeys.isSessionActive)
        let sessionIdString = defaults.string(forKey: AppGroupKeys.sessionId)
        let sessionId = sessionIdString.flatMap { UUID(uuidString: $0) }
        let message = defaults.string(forKey: AppGroupKeys.sessionMessage)
        let timeRemaining = defaults.double(forKey: AppGroupKeys.timeRemaining)
        
        return SessionState(
            isActive: isActive,
            sessionId: sessionId,
            message: message,
            timeRemaining: timeRemaining > 0 ? timeRemaining : nil
        )
    }
}

