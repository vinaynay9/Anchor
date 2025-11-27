import Foundation
import Combine

// MARK: - Notification Names
extension Notification.Name {
    public static let appGroupDidUpdate = Notification.Name("appGroupDidUpdate")
}

// MARK: - Unified Shared Session State (for Shield Extension)
public struct SharedSessionState: Codable {
    public let isActive: Bool
    public let endTime: Date?
    public let remainingSeconds: Int?
    
    public init(isActive: Bool, endTime: Date?, remainingSeconds: Int?) {
        self.isActive = isActive
        self.endTime = endTime
        self.remainingSeconds = remainingSeconds
    }
}

// MARK: - App Group Storage Service
public final class AppGroupStorage {
    public static let shared = AppGroupStorage()
    
    private let defaults: UserDefaults?
    
    private enum Keys {
        static let sharedSessionState = "sharedSessionState"
        static let pendingUnlockRequest = "hasPendingUnlockRequest"
    }
    
    // MARK: - Combine Publisher for Real-Time Updates
    public let updatesPublisher: AnyPublisher<String?, Never>
    
    private init() {
        defaults = UserDefaults(suiteName: "group.com.anchor.app")
        
        // Create Combine publisher for AppGroupStorage updates
        updatesPublisher = NotificationCenter.default
            .publisher(for: .appGroupDidUpdate)
            .map { notification -> String? in
                notification.object as? String
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Internal Helper to Post Notifications
    private func notifyUpdate(forKey key: String) {
        NotificationCenter.default.post(name: .appGroupDidUpdate, object: key)
    }
    
    // MARK: - Shared Session State
    
    public func getSessionState() -> SharedSessionState? {
        guard let data = defaults?.data(forKey: Keys.sharedSessionState) else { return nil }
        return try? JSONDecoder().decode(SharedSessionState.self, from: data)
    }
    
    public func setSessionState(_ state: SharedSessionState?) {
        guard let defaults = defaults else { return }
        
        if let state = state {
            let data = try? JSONEncoder().encode(state)
            defaults.set(data, forKey: Keys.sharedSessionState)
        } else {
            defaults.removeObject(forKey: Keys.sharedSessionState)
        }
        
        // Broadcast update notification
        notifyUpdate(forKey: Keys.sharedSessionState)
    }
    
    public func updateRemainingSeconds(_ seconds: Int) {
        guard var current = getSessionState() else { return }
        
        let updated = SharedSessionState(
            isActive: current.isActive,
            endTime: current.endTime,
            remainingSeconds: seconds
        )
        
        setSessionState(updated)
    }
    
    public func clearSessionState() {
        defaults?.removeObject(forKey: Keys.sharedSessionState)
        // Broadcast update notification
        notifyUpdate(forKey: Keys.sharedSessionState)
    }
    
    // MARK: - Unlock Request
    
    public func hasPendingUnlockRequest() -> Bool {
        defaults?.bool(forKey: Keys.pendingUnlockRequest) ?? false
    }
    
    public func setPendingUnlockRequest(_ isPending: Bool) {
        defaults?.set(isPending, forKey: Keys.pendingUnlockRequest)
        // Broadcast update notification
        notifyUpdate(forKey: Keys.pendingUnlockRequest)
    }
}
