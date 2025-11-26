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

// MARK: - Unified Shared Session State (for Shield Extension)
struct SharedSessionState: Codable {
    let isActive: Bool
    let endTime: Date?
    let remainingSeconds: Int?
}

// MARK: - App Group Storage Service
class AppGroupStorage {
    static let shared = AppGroupStorage()
    
    private let appGroupIdentifier = AppConfig.appGroupIdentifier
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Legacy Session State (for backward compatibility)
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
    
    func getLegacySessionState() -> SessionState {
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
    
    func clearLegacySessionState() {
        saveSessionState(.empty)
    }
    
    // MARK: - Shared Session State (for Shield Extension)
    
    /// Sets the shared session state for the shield extension
    func setSessionState(_ state: SharedSessionState?) {
        guard let defaults = userDefaults else { return }
        
        if let state = state {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(state) {
                defaults.set(encoded, forKey: "sharedSessionState")
            }
        } else {
            defaults.removeObject(forKey: "sharedSessionState")
        }
    }
    
    /// Sets the pending unlock request status
    func setPendingUnlockRequest(_ isPending: Bool) {
        guard let defaults = userDefaults else { return }
        defaults.set(isPending, forKey: "hasPendingUnlockRequest")
    }
    
    /// Gets the shared session state for the shield extension
    func getSessionState() -> SharedSessionState? {
        guard let defaults = userDefaults else { return nil }
        
        guard let data = defaults.data(forKey: "sharedSessionState") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(SharedSessionState.self, from: data)
    }
    
    /// Clears the shared session state
    func clearSessionState() {
        guard let defaults = userDefaults else { return }
        defaults.removeObject(forKey: "sharedSessionState")
    }
    
    /// Updates the remaining seconds in the shared session state
    func updateRemainingSeconds(_ seconds: Int) {
        guard let defaults = userDefaults else { return }
        
        var currentState = getSessionState() ?? SharedSessionState(
            isActive: false,
            endTime: nil,
            remainingSeconds: nil
        )
        
        let updatedState = SharedSessionState(
            isActive: currentState.isActive,
            endTime: currentState.endTime,
            remainingSeconds: seconds
        )
        
        setSessionState(updatedState)
    }
}

