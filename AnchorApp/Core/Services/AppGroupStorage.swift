import Foundation

// MARK: - Shared Session State
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

// MARK: - App Group Storage Service
class AppGroupStorage {
    static let shared = AppGroupStorage()
    
    private let appGroupIdentifier = AppConfig.appGroupIdentifier
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Session State
    func saveSessionState(_ state: SessionState) {
        guard let defaults = userDefaults else { return }
        
        defaults.set(state.isActive, forKey: AppConfig.AppGroupKeys.isSessionActive)
        if let sessionId = state.sessionId {
            defaults.set(sessionId.uuidString, forKey: AppConfig.AppGroupKeys.sessionId)
        } else {
            defaults.removeObject(forKey: AppConfig.AppGroupKeys.sessionId)
        }
        defaults.set(state.message, forKey: AppConfig.AppGroupKeys.sessionMessage)
        if let timeRemaining = state.timeRemaining {
            defaults.set(timeRemaining, forKey: AppConfig.AppGroupKeys.timeRemaining)
        } else {
            defaults.removeObject(forKey: AppConfig.AppGroupKeys.timeRemaining)
        }
    }
    
    func getSessionState() -> SessionState {
        guard let defaults = userDefaults else { return .empty }
        
        let isActive = defaults.bool(forKey: AppConfig.AppGroupKeys.isSessionActive)
        let sessionIdString = defaults.string(forKey: AppConfig.AppGroupKeys.sessionId)
        let sessionId = sessionIdString.flatMap { UUID(uuidString: $0) }
        let message = defaults.string(forKey: AppConfig.AppGroupKeys.sessionMessage)
        let timeRemaining = defaults.double(forKey: AppConfig.AppGroupKeys.timeRemaining)
        
        return SessionState(
            isActive: isActive,
            sessionId: sessionId,
            message: message,
            timeRemaining: timeRemaining > 0 ? timeRemaining : nil
        )
    }
    
    func clearSessionState() {
        saveSessionState(.empty)
    }
}

