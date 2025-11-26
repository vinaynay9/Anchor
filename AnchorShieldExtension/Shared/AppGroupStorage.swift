import Foundation

// MARK: - Unified Shared Session State (for Shield Extension)
// This must match the SharedSessionState in AnchorApp/Core/Services/AppGroupStorage.swift exactly
struct SharedSessionState: Codable {
    let isActive: Bool
    let endTime: Date?
    let remainingSeconds: Int?
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
    /// Gets the shared session state from App Group storage
    /// Reads from the "sharedSessionState" key (JSON-encoded) written by the main app
    func getSessionState() -> SharedSessionState? {
        guard let defaults = userDefaults else { return nil }
        
        guard let data = defaults.data(forKey: "sharedSessionState") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(SharedSessionState.self, from: data)
    }
    
    // MARK: - Unlock Request Status
    func hasPendingUnlockRequest() -> Bool {
        guard let defaults = userDefaults else { return false }
        return defaults.bool(forKey: "hasPendingUnlockRequest")
    }
}

