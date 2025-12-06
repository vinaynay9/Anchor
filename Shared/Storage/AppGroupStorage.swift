import Foundation
import Combine
import FamilyControls

// MARK: - Notification Names
extension Notification.Name {
    /// Notification posted when any AppGroupStorage value is updated.
    /// The notification object contains the key that was updated.
    public static let appGroupDidUpdate = Notification.Name("appGroupDidUpdate")
}

// MARK: - Deep Link Context
/// Represents context passed from shield extension to main app via deep link.
/// This struct ensures type-safe handling of deep link parameters.
public struct DeepLinkContext: Codable {
    /// The unlock request ID (if opening from an unlock request)
    public let unlockRequestId: String?
    /// The bundle ID of the blocked app (if opening from shield)
    public let bundleId: String?
    /// Timestamp when context was created
    public let createdAt: Date
    
    public init(unlockRequestId: String? = nil, bundleId: String? = nil) {
        self.unlockRequestId = unlockRequestId
        self.bundleId = bundleId
        self.createdAt = Date()
    }
    
    /// Checks if context is expired (older than 5 minutes)
    public var isExpired: Bool {
        let expirationTime = createdAt.addingTimeInterval(5 * 60)
        return Date() > expirationTime
    }
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
    
    /// **Key:** `"unlockApproved"`
    /// **Type:** Boolean
    /// **Purpose:** Indicates that an unlock request has been approved and the shield should auto-dismiss
    /// **Written by:** UnlockRequestService (when unlock request is approved)
    /// **Read by:** ShieldViewModel, ShieldDecision (to determine if shield should allow app)
    /// **Lifecycle:** Set to true when unlock approved, cleared when shield is dismissed or app is reopened
    case unlockApproved = "unlockApproved"
    
    /// **Key:** `"unlockAllowedBundleId"`
    /// **Type:** String (bundle identifier)
    /// **Purpose:** Stores the bundle ID of the app that has been approved for unlock
    /// **Written by:** UnlockRequestService (when unlock request is approved)
    /// **Read by:** ShieldViewModel, ShieldDecision (to determine which app to allow)
    /// **Lifecycle:** Set when unlock approved, cleared when shield is dismissed or app is reopened
    case unlockAllowedBundleId = "unlockAllowedBundleId"
    
    /// **Key:** `"unlockApprovedTimestamp"`
    /// **Type:** Date (stored as TimeInterval)
    /// **Purpose:** Stores the timestamp when the unlock was approved
    /// **Written by:** UnlockRequestService (when unlock request is approved)
    /// **Read by:** ShieldViewModel (to check if unlock is still valid)
    /// **Lifecycle:** Set when unlock approved, cleared when shield is dismissed or app is reopened
    case unlockApprovedTimestamp = "unlockApprovedTimestamp"
    
    /// **Key:** `"currentBlockedBundleId"`
    /// **Type:** String (bundle identifier)
    /// **Purpose:** Stores the bundle ID of the app currently showing the shield
    /// **Written by:** ShieldExtension/ShieldView (when shield is displayed)
    /// **Read by:** ShieldViewModel (to pass to unlock request flow)
    /// **Lifecycle:** Set when shield is shown, cleared when shield is dismissed
    case currentBlockedBundleId = "currentBlockedBundleId"
    
    /// **Key:** `"pendingDeepLinkContext"`
    /// **Type:** Dictionary with contextual info (e.g., unlockRequestId, bundleId)
    /// **Purpose:** Stores context passed from shield extension when opening app via URL scheme
    /// **Written by:** ShieldViewModel (when opening app from shield), DeepLinkHandler (when processing deep links)
    /// **Read by:** AppCoordinator (to navigate to correct screen with context)
    /// **Lifecycle:** Set when deep link is triggered, cleared after navigation completes
    case pendingDeepLinkContext = "pendingDeepLinkContext"
    
    /// **Key Prefix:** `"scheduledSessionConfig_"`  
    /// **Type:** Prefix for dynamic session-specific schedule configuration keys
    /// **Purpose:** Used to generate session-specific keys for scheduled session configurations
    /// **Usage:** Combined with session UUID via `scheduledSessionConfigurationKey(for:)` method
    case scheduledSessionConfigPrefix = "scheduledSessionConfig_"
    
    /// Generate a session-specific key for FamilyActivitySelection
    /// - Parameter sessionId: The session UUID
    /// - Returns: The full key string for this session's selection
    public static func familyActivitySelectionKey(for sessionId: UUID) -> String {
        return "\(familyActivitySelectionPrefix.rawValue)\(sessionId.uuidString)"
    }
    
    /// Generate a session-specific key for scheduled session configuration
    /// - Parameter sessionId: The session UUID
    /// - Returns: The full key string for this session's schedule configuration
    public static func scheduledSessionConfigurationKey(for sessionId: UUID) -> String {
        return "\(scheduledSessionConfigPrefix.rawValue)\(sessionId.uuidString)"
    }
    
    /// **Key Prefix:** `"scheduledSessionMetadata_"`  
    /// **Type:** Prefix for dynamic session-specific metadata keys
    /// **Purpose:** Used to generate session-specific keys for scheduled session metadata (duration, friends, categories)
    case scheduledSessionMetadataPrefix = "scheduledSessionMetadata_"
    
    /// Generate a session-specific key for scheduled session metadata
    /// - Parameter sessionId: The session UUID
    /// - Returns: The full key string for this session's metadata
    public static func scheduledSessionMetadataKey(for sessionId: UUID) -> String {
        return "\(scheduledSessionMetadataPrefix.rawValue)\(sessionId.uuidString)"
    }
    
    /// **Key Prefix:** `"sessionEvents_"`
    /// **Type:** Prefix for dynamic session-specific event keys
    /// **Purpose:** Used to generate session-specific keys for storing session events
    case sessionEventsPrefix = "sessionEvents_"
    
    /// Generate a session-specific key for session events
    /// - Parameter sessionId: The session UUID
    /// - Returns: The full key string for this session's events
    public static func sessionEventsKey(for sessionId: UUID) -> String {
        return "\(sessionEventsPrefix.rawValue)\(sessionId.uuidString)"
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
            LoggerService.shared.logInfo("Session state written to AppGroup: isActive=\(state.isActive)", category: "AppGroup")
        } else {
            defaults.removeObject(forKey: AppGroupStorageKey.sharedSessionState.rawValue)
            LoggerService.shared.logInfo("Session state cleared from AppGroup", category: "AppGroup")
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
        LoggerService.shared.logInfo("Pending unlock request flag set: \(isPending)", category: "AppGroup")
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
    
    // MARK: - Unlock Approval
    
    /// Checks if an unlock has been approved.
    /// Used by ShieldViewModel and ShieldDecision to determine if shield should auto-dismiss.
    /// - Returns: true if unlock has been approved, false otherwise
    public func isUnlockApproved() -> Bool {
        defaults?.bool(forKey: AppGroupStorageKey.unlockApproved.rawValue) ?? false
    }
    
    /// Sets the unlock approved flag.
    /// Called by UnlockRequestService when an unlock request is approved.
    /// - Parameter isApproved: Whether the unlock has been approved
    public func setUnlockApproved(_ isApproved: Bool) {
        defaults?.set(isApproved, forKey: AppGroupStorageKey.unlockApproved.rawValue)
        notifyUpdate(forKey: .unlockApproved)
    }
    
    /// Clears the unlock approved flag.
    /// Called when shield is dismissed or app is reopened after approval.
    public func clearUnlockApproved() {
        defaults?.removeObject(forKey: AppGroupStorageKey.unlockApproved.rawValue)
        notifyUpdate(forKey: .unlockApproved)
    }
    
    /// Sets the approved unlock bundle ID and timestamp.
    /// Called by UnlockRequestService when an unlock request is approved.
    /// - Parameters:
    ///   - bundleId: The bundle identifier of the app to allow
    ///   - timestamp: The timestamp when the unlock was approved
    public func setUnlockAllowedBundleId(_ bundleId: String, timestamp: Date = Date()) {
        defaults?.set(bundleId, forKey: AppGroupStorageKey.unlockAllowedBundleId.rawValue)
        defaults?.set(timestamp.timeIntervalSince1970, forKey: AppGroupStorageKey.unlockApprovedTimestamp.rawValue)
        notifyUpdate(forKey: .unlockAllowedBundleId)
    }
    
    /// Gets the approved unlock bundle ID.
    /// Used by ShieldViewModel to determine which app to allow.
    /// - Returns: The bundle identifier of the approved app, or nil if none
    public func getUnlockAllowedBundleId() -> String? {
        return defaults?.string(forKey: AppGroupStorageKey.unlockAllowedBundleId.rawValue)
    }
    
    /// Gets the timestamp when the unlock was approved.
    /// Used to check if the unlock is still valid.
    /// - Returns: The approval timestamp, or nil if none
    public func getUnlockApprovedTimestamp() -> Date? {
        guard let timestamp = defaults?.double(forKey: AppGroupStorageKey.unlockApprovedTimestamp.rawValue),
              timestamp > 0 else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    /// Clears the approved unlock bundle ID and timestamp.
    /// Called when shield is dismissed or app is reopened after approval.
    public func clearUnlockAllowedBundleId() {
        defaults?.removeObject(forKey: AppGroupStorageKey.unlockAllowedBundleId.rawValue)
        defaults?.removeObject(forKey: AppGroupStorageKey.unlockApprovedTimestamp.rawValue)
        notifyUpdate(forKey: .unlockAllowedBundleId)
    }
    
    // MARK: - Deep Link Context
    
    /// Sets context for a pending deep link (e.g., unlock request ID, bundle ID).
    /// Used when shield extension opens app via URL scheme to pass contextual information.
    /// - Parameters:
    ///   - requestId: Optional unlock request ID
    ///   - bundleId: Optional bundle ID of the blocked app
    public func setPendingDeepLinkContext(requestId: String? = nil, bundleId: String? = nil) {
        var context: [String: String] = [:]
        if let requestId = requestId {
            context["unlockRequestId"] = requestId
        }
        if let bundleId = bundleId {
            context["bundleId"] = bundleId
        }
        
        if !context.isEmpty {
            defaults?.set(context, forKey: AppGroupStorageKey.pendingDeepLinkContext.rawValue)
        } else {
            defaults?.removeObject(forKey: AppGroupStorageKey.pendingDeepLinkContext.rawValue)
        }
        notifyUpdate(forKey: .pendingDeepLinkContext)
    }
    
    /// Gets the pending deep link context.
    /// Used by AppCoordinator to navigate to the correct screen with context.
    /// - Returns: Dictionary with context (e.g., ["unlockRequestId": "123"])
    public func getPendingDeepLinkContext() -> [String: String] {
        guard let defaults = defaults,
              let context = defaults.dictionary(forKey: AppGroupStorageKey.pendingDeepLinkContext.rawValue) as? [String: String] else {
            return [:]
        }
        return context
    }
    
    /// Saves a type-safe DeepLinkContext.
    /// Preferred over setPendingDeepLinkContext for type safety.
    /// - Parameter context: The DeepLinkContext to save
    public func saveDeepLinkContext(_ context: DeepLinkContext) {
        guard let defaults = defaults else { return }
        
        do {
            let encoded = try JSONEncoder().encode(context)
            defaults.set(encoded, forKey: AppGroupStorageKey.pendingDeepLinkContext.rawValue)
            notifyUpdate(forKey: .pendingDeepLinkContext)
        } catch {
            // Fall back to dictionary format
            setPendingDeepLinkContext(requestId: context.unlockRequestId, bundleId: context.bundleId)
        }
    }
    
    /// Loads a type-safe DeepLinkContext.
    /// Returns nil if no context exists or if expired.
    /// - Returns: The stored DeepLinkContext, or nil
    public func loadDeepLinkContext() -> DeepLinkContext? {
        guard let defaults = defaults else { return nil }
        
        // Try to load as encoded struct first
        if let data = defaults.data(forKey: AppGroupStorageKey.pendingDeepLinkContext.rawValue),
           let context = try? JSONDecoder().decode(DeepLinkContext.self, from: data) {
            // Check if expired
            if context.isExpired {
                clearPendingDeepLinkContext()
                return nil
            }
            return context
        }
        
        // Fall back to dictionary format (for backward compatibility)
        let dict = getPendingDeepLinkContext()
        if dict.isEmpty {
            return nil
        }
        
        return DeepLinkContext(
            unlockRequestId: dict["unlockRequestId"],
            bundleId: dict["bundleId"]
        )
    }
    
    /// Clears the pending deep link context.
    /// Called after navigation completes.
    public func clearPendingDeepLinkContext() {
        defaults?.removeObject(forKey: AppGroupStorageKey.pendingDeepLinkContext.rawValue)
        notifyUpdate(forKey: .pendingDeepLinkContext)
    }
    
    // MARK: - Current Blocked Bundle ID
    
    /// Sets the bundle ID of the app currently showing the shield.
    /// Called when shield is displayed to track which app is blocked.
    /// - Parameter bundleId: The bundle identifier of the blocked app
    public func setCurrentBlockedBundleId(_ bundleId: String) {
        defaults?.set(bundleId, forKey: AppGroupStorageKey.currentBlockedBundleId.rawValue)
        notifyUpdate(forKey: .currentBlockedBundleId)
    }
    
    /// Gets the bundle ID of the app currently showing the shield.
    /// Used to pass bundle ID to unlock request flow.
    /// - Returns: The bundle identifier of the blocked app, or nil if not set
    public func getCurrentBlockedBundleId() -> String? {
        return defaults?.string(forKey: AppGroupStorageKey.currentBlockedBundleId.rawValue)
    }
    
    /// Clears the current blocked bundle ID.
    /// Called when shield is dismissed or app is unlocked.
    public func clearCurrentBlockedBundleId() {
        defaults?.removeObject(forKey: AppGroupStorageKey.currentBlockedBundleId.rawValue)
        notifyUpdate(forKey: .currentBlockedBundleId)
    }
    
    // MARK: - Unified Unlock Approval
    
    /// Sets all unlock approval flags atomically.
    /// This is the preferred method for approving an unlock request.
    /// - Parameters:
    ///   - bundleId: The bundle ID of the app to allow
    ///   - timestamp: The timestamp when the unlock was approved (defaults to now)
    public func setUnlockAllowed(bundleId: String, at timestamp: Date = Date()) {
        defaults?.set(true, forKey: AppGroupStorageKey.unlockApproved.rawValue)
        defaults?.set(bundleId, forKey: AppGroupStorageKey.unlockAllowedBundleId.rawValue)
        defaults?.set(timestamp.timeIntervalSince1970, forKey: AppGroupStorageKey.unlockApprovedTimestamp.rawValue)
        
        LoggerService.shared.logInfo("Unlock allowed for bundle: \(bundleId)", category: "AppGroup")
        
        notifyUpdate(forKey: .unlockApproved)
        notifyUpdate(forKey: .unlockAllowedBundleId)
    }
    
    /// Clears all unlock approval flags atomically.
    public func clearUnlockApproval() {
        defaults?.removeObject(forKey: AppGroupStorageKey.unlockApproved.rawValue)
        defaults?.removeObject(forKey: AppGroupStorageKey.unlockAllowedBundleId.rawValue)
        defaults?.removeObject(forKey: AppGroupStorageKey.unlockApprovedTimestamp.rawValue)
        
        LoggerService.shared.logInfo("Unlock approval cleared", category: "AppGroup")
        
        notifyUpdate(forKey: .unlockApproved)
        notifyUpdate(forKey: .unlockAllowedBundleId)
    }
    
    // MARK: - Unlock Flag Cleanup
    
    /// Checks if unlock approval has expired (5 minutes after approval).
    /// - Returns: true if unlock has expired, false otherwise
    public func isUnlockExpired() -> Bool {
        guard let timestamp = getUnlockApprovedTimestamp() else {
            return true // No timestamp means expired
        }
        let expirationTime = timestamp.addingTimeInterval(5 * 60) // 5 minutes
        return Date() > expirationTime
    }
    
    /// Cleans up expired unlock flags.
    /// Should be called periodically or when checking unlock status.
    public func cleanupExpiredUnlockFlags() {
        if isUnlockExpired() {
            clearUnlockApproval()
        }
    }
    
    // MARK: - Session Events
    
    /// Saves session events for a specific session.
    /// Used by SessionService to persist event timeline.
    /// - Parameters:
    ///   - events: Array of session events
    ///   - sessionId: The session UUID
    public func saveSessionEvents(_ events: [SessionEvent], forSessionId sessionId: UUID) {
        guard let defaults = defaults else { return }
        
        do {
            let encoded = try JSONEncoder().encode(events)
            let key = AppGroupStorageKey.sessionEventsKey(for: sessionId)
            defaults.set(encoded, forKey: key)
        } catch {
            // Log error but don't throw - events are non-critical
            print("Failed to save session events: \(error)")
        }
    }
    
    /// Loads session events for a specific session.
    /// Used by SessionService to restore event timeline.
    /// - Parameter sessionId: The session UUID
    /// - Returns: Array of session events, or empty array if not found
    public func loadSessionEvents(forSessionId sessionId: UUID) -> [SessionEvent] {
        guard let defaults = defaults else { return [] }
        
        let key = AppGroupStorageKey.sessionEventsKey(for: sessionId)
        guard let data = defaults.data(forKey: key) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([SessionEvent].self, from: data)
        } catch {
            print("Failed to load session events: \(error)")
            return []
        }
    }
    
    /// Clears session events for a specific session.
    /// - Parameter sessionId: The session UUID
    public func clearSessionEvents(forSessionId sessionId: UUID) {
        guard let defaults = defaults else { return }
        let key = AppGroupStorageKey.sessionEventsKey(for: sessionId)
        defaults.removeObject(forKey: key)
    }
}
