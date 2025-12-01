import Foundation
import Combine
import FamilyControls

// MARK: - Notification Names
extension Notification.Name {
    /// Notification posted when any AppGroupStorage value is updated.
    /// The notification object contains the key that was updated.
    public static let appGroupDidUpdate = Notification.Name("appGroupDidUpdate")
}

// MARK: - Unified Shared Session State (for Shield Extension)
/// Represents the current session state shared between AnchorApp and Shield Extension.
/// This state is written by SessionService and read by ShieldViewModel to display session information.
public struct SharedSessionState: Codable {
    /// Whether a focus session is currently active
    public let isActive: Bool
    /// The scheduled end time of the session (if applicable)
    public let endTime: Date?
    /// The remaining seconds in the session (updated in real-time by SessionService timer)
    public let remainingSeconds: Int?
    
    public init(isActive: Bool, endTime: Date?, remainingSeconds: Int?) {
        self.isActive = isActive
        self.endTime = endTime
        self.remainingSeconds = remainingSeconds
    }
}

// MARK: - App Group Storage Keys
/// Centralized enum for all AppGroup storage keys.
/// 
/// **Purpose:** Ensures all storage keys are consistent across AnchorApp and Shield Extension targets.
/// All keys used in AppGroupStorage must be defined here. Never use hardcoded string keys directly.
///
/// **Key Usage:**
/// - All keys are accessed via `AppGroupStorageKey.rawValue` to prevent typos and ensure consistency
/// - Session-specific keys are generated dynamically using `familyActivitySelectionKey(for:)`
/// - This enum is the single source of truth for all AppGroup storage key names
public enum AppGroupStorageKey: String {
    /// **Key:** `"sharedSessionState"`
    /// **Type:** JSON-encoded `SharedSessionState`
    /// **Purpose:** Stores the current active session state (isActive, endTime, remainingSeconds)
    /// **Written by:** SessionService (when sessions start/end/update)
    /// **Read by:** ShieldViewModel (to display session info on blocked apps)
    /// **Lifecycle:** Created when session starts, updated every second by timer, cleared when session ends
    case sharedSessionState = "sharedSessionState"
    
    /// **Key:** `"pendingUnlockRequest"`
    /// **Type:** Boolean
    /// **Purpose:** Indicates whether the user has sent an unlock request that is awaiting partner approval
    /// **Written by:** UnlockRequestService (when requests are sent, approved, or denied)
    /// **Read by:** ShieldViewModel (to show "waiting for approval" UI state)
    /// **Lifecycle:** Set to true when request sent, false when approved/denied/cancelled
    case pendingUnlockRequest = "pendingUnlockRequest"
    
    /// **Key:** `"familyActivitySelection"`
    /// **Type:** JSON-encoded `FamilyActivitySelection`
    /// **Purpose:** Stores the main/persistent app selection that applies to all sessions
    /// **Written by:** ActivitySelectionService, SelectAppsViewModel (when user selects apps)
    /// **Read by:** ActivitySelectionService, ScreenTimeService (to apply app blocking)
    /// **Lifecycle:** Persists across app launches, cleared when user explicitly clears selection
    case familyActivitySelection = "familyActivitySelection"
    
    /// **Key Prefix:** `"familyActivitySelection_"`
    /// **Type:** Prefix for dynamic session-specific keys
    /// **Purpose:** Used to generate session-specific keys (format: "familyActivitySelection_{sessionId}")
    /// **Usage:** Combined with session UUID via `familyActivitySelectionKey(for:)` method
    /// **Written by:** ScreenTimeService (when session-specific selections are saved)
    /// **Read by:** ScreenTimeService (to restore session-specific app selections)
    /// **Lifecycle:** Created per session, persists until session ends or is manually cleared
    case familyActivitySelectionPrefix = "familyActivitySelection_"
    
    /// **Key:** `"currentSessionFriendIds"`
    /// **Type:** Array of String (UUID strings)
    /// **Purpose:** Stores the friend IDs associated with the current active session
    /// **Written by:** SessionService (when session starts with friends)
    /// **Read by:** SessionService (to restore friend associations on app restart)
    /// **Lifecycle:** Set when session starts, cleared when session ends
    case currentSessionFriendIds = "currentSessionFriendIds"
    
    /// Generate a session-specific key for FamilyActivitySelection
    /// - Parameter sessionId: The session UUID
    /// - Returns: The full key string for this session's selection
    public static func familyActivitySelectionKey(for sessionId: UUID) -> String {
        return "\(familyActivitySelectionPrefix.rawValue)\(sessionId.uuidString)"
    }
}

// MARK: - App Group Storage Service
/// Centralized service for reading and writing shared data between AnchorApp and Shield Extension.
///
/// **Purpose:**
/// This service provides a unified interface for all AppGroup storage operations, ensuring:
/// - Consistent key usage across all targets (AnchorApp and Shield Extension)
/// - Automatic notification broadcasting when values change
/// - Type-safe access to stored values
/// - Single source of truth for the App Group identifier
///
/// **Architecture:**
/// - Uses `UserDefaults(suiteName:)` with App Group identifier for shared storage
/// - All keys are defined in `AppGroupStorageKey` enum to prevent inconsistencies
/// - Publishes updates via Combine and NotificationCenter for real-time synchronization
/// - Both AnchorApp and Shield Extension use the same `AppGroupStorage.shared` instance
///
/// **Usage by Service:**
/// - **SessionService:** Writes `SharedSessionState` when sessions start/end/update
/// - **ShieldViewModel:** Reads `SharedSessionState` to display session info on blocked apps
/// - **UnlockRequestService:** Manages `pendingUnlockRequest` flag for unlock request flow
/// - **ActivitySelectionService:** Manages `familyActivitySelection` for app blocking
/// - **ScreenTimeService:** Manages session-specific app selections
///
/// **Important Notes:**
/// - Never access AppGroup UserDefaults directly - always use this service
/// - Never use hardcoded key strings - always use `AppGroupStorageKey` enum
/// - The App Group identifier must match in both AnchorApp and Shield Extension targets
/// - All stored values are automatically synchronized between app and extension
public final class AppGroupStorage {
    public static let shared = AppGroupStorage()
    
    private let defaults: UserDefaults?
    
    /// The App Group identifier used for shared UserDefaults.
    /// Must match the App Group identifier configured in both AnchorApp and AnchorShieldExtension targets.
    /// This is the single source of truth for the App Group identifier across all targets.
    public static let appGroupIdentifier = "group.com.anchor.app"
    
    // MARK: - Combine Publisher for Real-Time Updates
    public let updatesPublisher: AnyPublisher<String?, Never>
    
    private init() {
        defaults = UserDefaults(suiteName: Self.appGroupIdentifier)
        
        // Create Combine publisher for AppGroupStorage updates
        updatesPublisher = NotificationCenter.default
            .publisher(for: .appGroupDidUpdate)
            .map { notification -> String? in
                notification.object as? String
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Internal Helper to Post Notifications
    private func notifyUpdate(forKey key: AppGroupStorageKey) {
        NotificationCenter.default.post(name: .appGroupDidUpdate, object: key.rawValue)
    }
    
    // MARK: - Shared Session State
    
    /// Retrieves the current session state from AppGroup storage.
    /// Used by ShieldViewModel to display session information.
    /// - Returns: The current SharedSessionState, or nil if no active session
    public func getSessionState() -> SharedSessionState? {
        guard let data = defaults?.data(forKey: AppGroupStorageKey.sharedSessionState.rawValue) else { return nil }
        return try? JSONDecoder().decode(SharedSessionState.self, from: data)
    }
    
    /// Sets the session state in AppGroup storage.
    /// Called by SessionService when sessions start or end.
    /// - Parameter state: The session state to store, or nil to clear
    public func setSessionState(_ state: SharedSessionState?) {
        guard let defaults = defaults else { return }
        
        if let state = state {
            let data = try? JSONEncoder().encode(state)
            defaults.set(data, forKey: AppGroupStorageKey.sharedSessionState.rawValue)
        } else {
            defaults.removeObject(forKey: AppGroupStorageKey.sharedSessionState.rawValue)
        }
        
        // Broadcast update notification
        notifyUpdate(forKey: .sharedSessionState)
    }
    
    /// Updates only the remaining seconds in the current session state.
    /// Called by SessionService timer to update countdown in real-time.
    /// - Parameter seconds: The new remaining seconds value
    public func updateRemainingSeconds(_ seconds: Int) {
        guard var current = getSessionState() else { return }
        
        let updated = SharedSessionState(
            isActive: current.isActive,
            endTime: current.endTime,
            remainingSeconds: seconds
        )
        
        setSessionState(updated)
    }
    
    /// Clears the session state from AppGroup storage.
    /// Called when sessions end or unlock requests are approved.
    public func clearSessionState() {
        defaults?.removeObject(forKey: AppGroupStorageKey.sharedSessionState.rawValue)
        // Broadcast update notification
        notifyUpdate(forKey: .sharedSessionState)
    }
    
    // MARK: - Unlock Request
    
    /// Checks if there is a pending unlock request.
    /// Used by ShieldViewModel to show "waiting for approval" state.
    /// - Returns: true if an unlock request is pending, false otherwise
    public func hasPendingUnlockRequest() -> Bool {
        defaults?.bool(forKey: AppGroupStorageKey.pendingUnlockRequest.rawValue) ?? false
    }
    
    /// Sets the pending unlock request flag.
    /// Called by UnlockRequestService when requests are sent, approved, or denied.
    /// - Parameter isPending: Whether an unlock request is pending
    public func setPendingUnlockRequest(_ isPending: Bool) {
        defaults?.set(isPending, forKey: AppGroupStorageKey.pendingUnlockRequest.rawValue)
        // Broadcast update notification
        notifyUpdate(forKey: .pendingUnlockRequest)
    }
    
    // MARK: - Family Activity Selection
    
    /// Saves a FamilyActivitySelection to AppGroup storage.
    /// Used by ActivitySelectionService to persist app selections.
    /// - Parameters:
    ///   - selection: The FamilyActivitySelection to save
    ///   - key: The storage key to use (defaults to main selection key)
    /// - Returns: true if save succeeded, false otherwise
    @discardableResult
    public func saveFamilyActivitySelection(_ selection: FamilyActivitySelection, forKey key: AppGroupStorageKey = .familyActivitySelection) -> Bool {
        return saveFamilyActivitySelection(selection, forKeyString: key.rawValue)
    }
    
    /// Internal method to save FamilyActivitySelection with a raw string key.
    /// Used for both enum keys and dynamic session-specific keys.
    private func saveFamilyActivitySelection(_ selection: FamilyActivitySelection, forKeyString keyString: String) -> Bool {
        guard let defaults = defaults else { return false }
        
        do {
            let encoded = try JSONEncoder().encode(selection)
            defaults.set(encoded, forKey: keyString)
            // Only notify if it's a known enum key
            if let key = AppGroupStorageKey(rawValue: keyString) {
                notifyUpdate(forKey: key)
            }
            return true
        } catch {
            return false
        }
    }
    
    /// Loads a FamilyActivitySelection from AppGroup storage.
    /// Used by ActivitySelectionService to restore app selections.
    /// - Parameter key: The storage key to use (defaults to main selection key)
    /// - Returns: The stored FamilyActivitySelection, or nil if not found
    public func loadFamilyActivitySelection(forKey key: AppGroupStorageKey = .familyActivitySelection) -> FamilyActivitySelection? {
        return loadFamilyActivitySelection(forKeyString: key.rawValue)
    }
    
    /// Internal method to load FamilyActivitySelection with a raw string key.
    /// Used for both enum keys and dynamic session-specific keys.
    private func loadFamilyActivitySelection(forKeyString keyString: String) -> FamilyActivitySelection? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: keyString) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            return nil
        }
    }
    
    /// Removes a FamilyActivitySelection from AppGroup storage.
    /// - Parameter key: The storage key to use (defaults to main selection key)
    public func clearFamilyActivitySelection(forKey key: AppGroupStorageKey = .familyActivitySelection) {
        clearFamilyActivitySelection(forKeyString: key.rawValue)
    }
    
    /// Internal method to clear FamilyActivitySelection with a raw string key.
    private func clearFamilyActivitySelection(forKeyString keyString: String) {
        defaults?.removeObject(forKey: keyString)
        // Only notify if it's a known enum key
        if let key = AppGroupStorageKey(rawValue: keyString) {
            notifyUpdate(forKey: key)
        }
    }
    
    /// Saves a session-specific FamilyActivitySelection to AppGroup storage.
    /// Used by ScreenTimeService to persist app selections per session.
    /// - Parameters:
    ///   - selection: The FamilyActivitySelection to save
    ///   - sessionId: The session UUID to associate with this selection
    /// - Returns: true if save succeeded, false otherwise
    @discardableResult
    public func saveFamilyActivitySelection(_ selection: FamilyActivitySelection, forSessionId sessionId: UUID) -> Bool {
        let key = AppGroupStorageKey.familyActivitySelectionKey(for: sessionId)
        return saveFamilyActivitySelection(selection, forKeyString: key)
    }
    
    /// Loads a session-specific FamilyActivitySelection from AppGroup storage.
    /// Used by ScreenTimeService to restore app selections per session.
    /// - Parameter sessionId: The session UUID to load the selection for
    /// - Returns: The stored FamilyActivitySelection, or nil if not found
    public func loadFamilyActivitySelection(forSessionId sessionId: UUID) -> FamilyActivitySelection? {
        let key = AppGroupStorageKey.familyActivitySelectionKey(for: sessionId)
        return loadFamilyActivitySelection(forKeyString: key)
    }
    
    /// Removes a session-specific FamilyActivitySelection from AppGroup storage.
    /// - Parameter sessionId: The session UUID to clear the selection for
    public func clearFamilyActivitySelection(forSessionId sessionId: UUID) {
        let key = AppGroupStorageKey.familyActivitySelectionKey(for: sessionId)
        clearFamilyActivitySelection(forKeyString: key)
    }
    
    // MARK: - Session Friend IDs
    
    /// Saves the current session's friend IDs to AppGroup storage.
    /// Used by SessionService to persist friend associations with sessions.
    /// - Parameter friendIds: Array of friend UUID strings
    public func saveCurrentSessionFriendIds(_ friendIds: [String]) {
        defaults?.set(friendIds, forKey: AppGroupStorageKey.currentSessionFriendIds.rawValue)
        notifyUpdate(forKey: .currentSessionFriendIds)
    }
    
    /// Loads the current session's friend IDs from AppGroup storage.
    /// Used by SessionService to restore friend associations.
    /// - Returns: Array of friend UUID strings, or empty array if not found
    public func loadCurrentSessionFriendIds() -> [String] {
        guard let defaults = defaults,
              let friendIds = defaults.array(forKey: AppGroupStorageKey.currentSessionFriendIds.rawValue) as? [String] else {
            return []
        }
        return friendIds
    }
    
    /// Clears the current session's friend IDs from AppGroup storage.
    public func clearCurrentSessionFriendIds() {
        defaults?.removeObject(forKey: AppGroupStorageKey.currentSessionFriendIds.rawValue)
        notifyUpdate(forKey: .currentSessionFriendIds)
    }
}
