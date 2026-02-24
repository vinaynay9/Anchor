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

    /// **Key:** `"unlockedFamilyActivitySelection"`
    /// **Type:** JSON-encoded `FamilyActivitySelection`
    /// **Purpose:** Stores the app selection that can be unlocked per goal (V1 policy mode)
    /// **Written by:** OnboardingAppSelectionViewModel
    /// **Read by:** DailyGoalService, ScreenTimeService
    /// **Lifecycle:** Persists across launches, cleared if onboarding is reset
    case unlockedFamilyActivitySelection = "unlockedFamilyActivitySelection"
    
    /// **Key Prefix:** `"familyActivitySelection_"`
    /// **Type:** Prefix for dynamic session-specific keys
    /// **Purpose:** Used to generate session-specific keys (format: "familyActivitySelection_{sessionId}")
    /// **Usage:** Combined with session UUID via `familyActivitySelectionKey(for:)` method
    /// **Written by:** ScreenTimeService (when session-specific selections are saved)
    /// **Read by:** ScreenTimeService (to restore session-specific app selections)
    /// **Lifecycle:** Created per session, persists until session ends or is manually cleared
    case familyActivitySelectionPrefix = "familyActivitySelection_"

    /// **Key:** `"dailyGoalProgress"`
    /// **Type:** JSON-encoded `DailyGoalProgress`
    /// **Purpose:** Stores daily completion state for onboarding goals
    /// **Written by:** DailyGoalService
    /// **Read by:** DailyGoalService, Goals UI, Shield
    /// **Lifecycle:** Resets each local day
    case dailyGoalProgress = "dailyGoalProgress"

    /// **Key:** `"lastDailyAnchorAppliedDate"`
    /// **Type:** String (YYYY-MM-DD, local)
    /// **Purpose:** Tracks when daily anchoring was last applied
    /// **Written by:** DailyAnchorService
    /// **Read by:** DailyAnchorService
    case lastDailyAnchorAppliedDate = "lastDailyAnchorAppliedDate"

    /// **Key:** `"temporaryUnlockUntil"`
    /// **Type:** TimeInterval (since 1970)
    /// **Purpose:** Tracks temporary unlock expiration time
    /// **Written by:** ScreenTimeService
    /// **Read by:** DailyAnchorService
    case temporaryUnlockUntil = "temporaryUnlockUntil"
    
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

    /// **Key:** `"dailyAnchorTime"`
    /// **Type:** JSON-encoded `DailyAnchorTime`
    /// **Purpose:** Stores the user-defined daily anchor time for automatic anchoring.
    case dailyAnchorTime = "dailyAnchorTime"

    /// **Key:** `"anchoringEligibility"`
    /// **Type:** Boolean
    /// **Purpose:** Stores whether the user is currently eligible to be anchored.
    case anchoringEligibility = "anchoringEligibility"

    /// **Key:** `"emergencyUnanchorUntil"`
    /// **Type:** Date (stored as TimeInterval)
    /// **Purpose:** Stores the timestamp until which emergency unanchor is active.
    case emergencyUnanchorUntil = "emergencyUnanchorUntil"

    /// **Key:** `"lastShieldHitAt"`
    /// **Type:** Date (stored as TimeInterval)
    /// **Purpose:** Stores the timestamp of the most recent shield display.
    case lastShieldHitAt = "lastShieldHitAt"

    /// **Key:** `"analyticsSalt"`
    /// **Type:** String
    /// **Purpose:** Per-install salt used for hashing analytics tokens.
    case analyticsSalt = "analyticsSalt"

    /// **Key:** `"analyticsDayId"`
    /// **Type:** String
    /// **Purpose:** Daily identifier used for aggregate correlation.
    case analyticsDayId = "analyticsDayId"

    /// **Key:** `"analyticsDayIdDate"`
    /// **Type:** String (yyyy-MM-dd)
    /// **Purpose:** Date associated with the current analytics day ID.
    case analyticsDayIdDate = "analyticsDayIdDate"

    /// **Key:** `"analyticsUserId"`
    /// **Type:** String (UUID)
    /// **Purpose:** Stable per-install analytics user identifier.
    case analyticsUserId = "analyticsUserId"

    /// **Key:** `"profileDisplayName"`
    /// **Type:** String
    /// **Purpose:** Local profile display name collected during onboarding.
    case profileDisplayName = "profileDisplayName"

    /// **Key:** `"profileBirthMonth"`
    /// **Type:** Int
    /// **Purpose:** Local profile birth month (1..12).
    case profileBirthMonth = "profileBirthMonth"

    /// **Key:** `"profileBirthDay"`
    /// **Type:** Int
    /// **Purpose:** Local profile birth day (1..31).
    case profileBirthDay = "profileBirthDay"

    /// **Key:** `"profileTimezone"`
    /// **Type:** String
    /// **Purpose:** Local profile timezone identifier.
    case profileTimezone = "profileTimezone"

    /// **Key:** `"profileFirstName"`
    /// **Type:** String
    /// **Purpose:** Local profile first name.
    case profileFirstName = "profileFirstName"

    /// **Key:** `"profileLastName"`
    /// **Type:** String
    /// **Purpose:** Local profile last name.
    case profileLastName = "profileLastName"

    /// **Key:** `"profileBirthday"`
    /// **Type:** String
    /// **Purpose:** Local profile birthday (YYYY-MM-DD).
    case profileBirthday = "profileBirthday"

    /// **Key:** `"profileComplete"`
    /// **Type:** Bool
    /// **Purpose:** Whether required profile fields have been collected.
    case profileComplete = "profileComplete"

    /// **Key:** `"inviteState"`
    /// **Type:** JSON-encoded `InviteState`
    /// **Purpose:** Stores the current invite link and stats for the user/device.
    case inviteState = "inviteState"

    /// **Key:** `"inviteAttribution"`
    /// **Type:** JSON-encoded `InviteAttribution`
    /// **Purpose:** Stores pending invite attribution from a deep link.
    case inviteAttribution = "inviteAttribution"

    /// **Key:** `"onboardingState"`
    /// **Type:** JSON-encoded `OnboardingState`
    /// **Purpose:** Stores post-auth onboarding state machine progress.
    case onboardingState = "onboardingState"

    /// **Key:** `"lastAppOpenAt"`
    /// **Type:** Date (stored as TimeInterval)
    /// **Purpose:** Timestamp of the most recent app_opened event (dedup).
    case lastAppOpenAt = "lastAppOpenAt"
    
    /// **Key:** `"remote_app_config"`
    /// **Type:** JSON-encoded `RemoteAppConfig`
    /// **Purpose:** Stores the latest remote config fetched from backend.
    case remoteAppConfig = "remote_app_config"

    /// **Key:** `"lockPlans"`
    /// **Type:** JSON-encoded `[LockPlan]`
    /// **Purpose:** Stores user-defined lock plans (intent).
    case lockPlans = "lockPlans"
    
    /// **Key:** `"socialContracts"`
    /// **Type:** JSON-encoded `[SocialContract]`
    /// **Purpose:** Stores enforceable social contracts.
    case socialContracts = "socialContracts"
    
    /// **Key:** `"iouLedger"`
    /// **Type:** JSON-encoded `[IOULedgerEntry]`
    /// **Purpose:** Stores local IOU ledger entries from contracts.
    case iouLedger = "iouLedger"
    
    /// **Key:** `"shieldState"`
    /// **Type:** JSON-encoded `ShieldState`
    /// **Purpose:** Source-of-truth shield UI state (reason + metadata).
    case shieldState = "shieldState"
    
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

    /// **Key Prefix:** `"quorumState_"`
    /// **Type:** Prefix for dynamic session-specific quorum state keys
    /// **Purpose:** Stores quorum state per group session
    case quorumStatePrefix = "quorumState_"
    
    /// Generate a session-specific key for session events
    /// - Parameter sessionId: The session UUID
    /// - Returns: The full key string for this session's events
    public static func sessionEventsKey(for sessionId: UUID) -> String {
        return "\(sessionEventsPrefix.rawValue)\(sessionId.uuidString)"
    }
    
    /// Generate a session-specific key for quorum state
    /// - Parameter sessionId: The session UUID
    /// - Returns: The full key string for this session's quorum state
    public static func quorumStateKey(for sessionId: UUID) -> String {
        return "\(quorumStatePrefix.rawValue)\(sessionId.uuidString)"
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
    private static var didLogAppGroupFailure = false
    
    /// The App Group identifier used for shared UserDefaults.
    /// Must match the App Group identifier configured in both AnchorApp and AnchorShieldExtension targets.
    /// This is the single source of truth for the App Group identifier across all targets.
    public static let appGroupIdentifier = "group.com.vinay.anchor"
    
    // MARK: - Combine Publisher for Real-Time Updates
    public let updatesPublisher: AnyPublisher<String?, Never>
    
    private init() {
        let suiteDefaults = UserDefaults(suiteName: Self.appGroupIdentifier)
        if suiteDefaults == nil {
            AppGroupStorage.logAppGroupFailureOnce("⚠️ [AppGroupStorage] App Group suite not available: \(Self.appGroupIdentifier)")
            #if DEBUG
            defaults = UserDefaults.standard
            #else
            defaults = nil
            #endif
        } else {
            defaults = suiteDefaults
        }
        
        // Create Combine publisher for AppGroupStorage updates
        updatesPublisher = NotificationCenter.default
            .publisher(for: .appGroupDidUpdate)
            .map { notification -> String? in
                notification.object as? String
            }
            .eraseToAnyPublisher()
    }

    public func appGroupContainerURL() -> URL? {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) {
            return url
        }
        AppGroupStorage.logAppGroupFailureOnce("⚠️ [AppGroupStorage] Failed to resolve container URL for \(Self.appGroupIdentifier)")
        #if DEBUG
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        #else
        return nil
        #endif
    }

    private static func logAppGroupFailureOnce(_ message: String) {
        guard !didLogAppGroupFailure else { return }
        didLogAppGroupFailure = true
        print(message)
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
        guard let current = getSessionState() else { return }
        
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

    // MARK: - Unlocked App Selection

    @discardableResult
    public func saveUnlockedFamilyActivitySelection(_ selection: FamilyActivitySelection) -> Bool {
        return saveFamilyActivitySelection(selection, forKey: .unlockedFamilyActivitySelection)
    }

    public func loadUnlockedFamilyActivitySelection() -> FamilyActivitySelection? {
        return loadFamilyActivitySelection(forKey: .unlockedFamilyActivitySelection)
    }

    public func clearUnlockedFamilyActivitySelection() {
        clearFamilyActivitySelection(forKey: .unlockedFamilyActivitySelection)
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
        notifyUpdate(forKey: .unlockApproved)
        notifyUpdate(forKey: .unlockAllowedBundleId)
    }
    
    /// Clears all unlock approval flags atomically.
    public func clearUnlockApproval() {
        defaults?.removeObject(forKey: AppGroupStorageKey.unlockApproved.rawValue)
        defaults?.removeObject(forKey: AppGroupStorageKey.unlockAllowedBundleId.rawValue)
        defaults?.removeObject(forKey: AppGroupStorageKey.unlockApprovedTimestamp.rawValue)
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

    // MARK: - Anchoring Schedule

    public func setDailyAnchorTime(_ time: DailyAnchorTime) {
        guard let defaults = defaults else { return }
        if let data = try? JSONEncoder().encode(time) {
            defaults.set(data, forKey: AppGroupStorageKey.dailyAnchorTime.rawValue)
            notifyUpdate(forKey: .dailyAnchorTime)
        }
    }

    public func getDailyAnchorTime() -> DailyAnchorTime? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.dailyAnchorTime.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(DailyAnchorTime.self, from: data)
    }

    // MARK: - Daily Goal Progress

    public func setDailyGoalProgress(_ progress: DailyGoalProgress?) {
        guard let defaults = defaults else { return }
        if let progress = progress, let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: AppGroupStorageKey.dailyGoalProgress.rawValue)
        } else {
            defaults.removeObject(forKey: AppGroupStorageKey.dailyGoalProgress.rawValue)
        }
        notifyUpdate(forKey: .dailyGoalProgress)
    }

    public func getDailyGoalProgress() -> DailyGoalProgress? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.dailyGoalProgress.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(DailyGoalProgress.self, from: data)
    }

    // MARK: - Daily Anchor Applied Date

    public func setLastDailyAnchorAppliedDate(_ dateString: String?) {
        if let dateString = dateString {
            defaults?.set(dateString, forKey: AppGroupStorageKey.lastDailyAnchorAppliedDate.rawValue)
        } else {
            defaults?.removeObject(forKey: AppGroupStorageKey.lastDailyAnchorAppliedDate.rawValue)
        }
        notifyUpdate(forKey: .lastDailyAnchorAppliedDate)
    }

    public func getLastDailyAnchorAppliedDate() -> String? {
        defaults?.string(forKey: AppGroupStorageKey.lastDailyAnchorAppliedDate.rawValue)
    }

    // MARK: - Temporary Unlock

    public func setTemporaryUnlockUntil(_ date: Date?) {
        if let date = date {
            defaults?.set(date.timeIntervalSince1970, forKey: AppGroupStorageKey.temporaryUnlockUntil.rawValue)
        } else {
            defaults?.removeObject(forKey: AppGroupStorageKey.temporaryUnlockUntil.rawValue)
        }
        notifyUpdate(forKey: .temporaryUnlockUntil)
    }

    public func getTemporaryUnlockUntil() -> Date? {
        let ts = defaults?.double(forKey: AppGroupStorageKey.temporaryUnlockUntil.rawValue) ?? 0
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    public func setAnchoringEligibility(_ isEligible: Bool) {
        defaults?.set(isEligible, forKey: AppGroupStorageKey.anchoringEligibility.rawValue)
        notifyUpdate(forKey: .anchoringEligibility)
    }

    public func getAnchoringEligibility() -> Bool {
        defaults?.bool(forKey: AppGroupStorageKey.anchoringEligibility.rawValue) ?? false
    }

    // MARK: - Emergency Unanchor

    public func setEmergencyUnanchorUntil(_ date: Date?) {
        if let date = date {
            defaults?.set(date.timeIntervalSince1970, forKey: AppGroupStorageKey.emergencyUnanchorUntil.rawValue)
        } else {
            defaults?.removeObject(forKey: AppGroupStorageKey.emergencyUnanchorUntil.rawValue)
        }
        notifyUpdate(forKey: .emergencyUnanchorUntil)
    }

    public func getEmergencyUnanchorUntil() -> Date? {
        let timestamp = defaults?.double(forKey: AppGroupStorageKey.emergencyUnanchorUntil.rawValue) ?? 0
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    public func isEmergencyUnanchorActive() -> Bool {
        guard let until = getEmergencyUnanchorUntil() else { return false }
        return Date() < until
    }

    // MARK: - Shield Analytics Helpers

    public func setLastShieldHit(at date: Date) {
        defaults?.set(date.timeIntervalSince1970, forKey: AppGroupStorageKey.lastShieldHitAt.rawValue)
        notifyUpdate(forKey: .lastShieldHitAt)
    }

    public func getLastShieldHitAt() -> Date? {
        let timestamp = defaults?.double(forKey: AppGroupStorageKey.lastShieldHitAt.rawValue) ?? 0
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    public func getOrCreateAnalyticsSalt() -> String {
        if let salt = defaults?.string(forKey: AppGroupStorageKey.analyticsSalt.rawValue), !salt.isEmpty {
            return salt
        }
        let salt = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        defaults?.set(salt, forKey: AppGroupStorageKey.analyticsSalt.rawValue)
        notifyUpdate(forKey: .analyticsSalt)
        return salt
    }

    public func getOrCreateAnalyticsUserId() -> String {
        if let existingId = defaults?.string(forKey: AppGroupStorageKey.analyticsUserId.rawValue),
           !existingId.isEmpty {
            return existingId
        }
        let newId = UUID().uuidString
        defaults?.set(newId, forKey: AppGroupStorageKey.analyticsUserId.rawValue)
        notifyUpdate(forKey: .analyticsUserId)
        return newId
    }

    public func getAnalyticsDayId(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: date)
        let storedDate = defaults?.string(forKey: AppGroupStorageKey.analyticsDayIdDate.rawValue)
        if storedDate == today,
           let existingId = defaults?.string(forKey: AppGroupStorageKey.analyticsDayId.rawValue),
           !existingId.isEmpty {
            return existingId
        }
        let newId = UUID().uuidString
        defaults?.set(newId, forKey: AppGroupStorageKey.analyticsDayId.rawValue)
        defaults?.set(today, forKey: AppGroupStorageKey.analyticsDayIdDate.rawValue)
        notifyUpdate(forKey: .analyticsDayId)
        return newId
    }

    // MARK: - Profile

    public func setProfile(displayName: String, birthMonth: Int, birthDay: Int, timezone: String) {
        defaults?.set(displayName, forKey: AppGroupStorageKey.profileDisplayName.rawValue)
        defaults?.set(birthMonth, forKey: AppGroupStorageKey.profileBirthMonth.rawValue)
        defaults?.set(birthDay, forKey: AppGroupStorageKey.profileBirthDay.rawValue)
        defaults?.set(timezone, forKey: AppGroupStorageKey.profileTimezone.rawValue)
        defaults?.set(true, forKey: AppGroupStorageKey.profileComplete.rawValue)
        notifyUpdate(forKey: .profileDisplayName)
        notifyUpdate(forKey: .profileBirthMonth)
        notifyUpdate(forKey: .profileBirthDay)
        notifyUpdate(forKey: .profileTimezone)
        notifyUpdate(forKey: .profileComplete)
    }

    public func setPersonalInfo(firstName: String, lastName: String, birthday: String) {
        defaults?.set(firstName, forKey: AppGroupStorageKey.profileFirstName.rawValue)
        defaults?.set(lastName, forKey: AppGroupStorageKey.profileLastName.rawValue)
        defaults?.set(birthday, forKey: AppGroupStorageKey.profileBirthday.rawValue)
        defaults?.set(true, forKey: AppGroupStorageKey.profileComplete.rawValue)
        notifyUpdate(forKey: .profileFirstName)
        notifyUpdate(forKey: .profileLastName)
        notifyUpdate(forKey: .profileBirthday)
        notifyUpdate(forKey: .profileComplete)
    }

    public func getProfile() -> (displayName: String, birthMonth: Int, birthDay: Int, timezone: String)? {
        guard let displayName = defaults?.string(forKey: AppGroupStorageKey.profileDisplayName.rawValue),
              !displayName.isEmpty else {
            return nil
        }
        let birthMonth = defaults?.integer(forKey: AppGroupStorageKey.profileBirthMonth.rawValue) ?? 0
        let birthDay = defaults?.integer(forKey: AppGroupStorageKey.profileBirthDay.rawValue) ?? 0
        guard birthMonth >= 1, birthMonth <= 12, birthDay >= 1, birthDay <= 31 else {
            return nil
        }
        let timezone = defaults?.string(forKey: AppGroupStorageKey.profileTimezone.rawValue) ?? TimeZone.current.identifier
        return (displayName, birthMonth, birthDay, timezone)
    }

    public func getPersonalInfo() -> (firstName: String, lastName: String, birthday: String)? {
        guard let firstName = defaults?.string(forKey: AppGroupStorageKey.profileFirstName.rawValue),
              let lastName = defaults?.string(forKey: AppGroupStorageKey.profileLastName.rawValue),
              let birthday = defaults?.string(forKey: AppGroupStorageKey.profileBirthday.rawValue),
              !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !birthday.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return (firstName, lastName, birthday)
    }

    public func isPersonalInfoComplete() -> Bool {
        getPersonalInfo() != nil
    }

    public func isProfileComplete() -> Bool {
        defaults?.bool(forKey: AppGroupStorageKey.profileComplete.rawValue) ?? false
    }

    public func setProfileComplete(_ complete: Bool) {
        defaults?.set(complete, forKey: AppGroupStorageKey.profileComplete.rawValue)
        notifyUpdate(forKey: .profileComplete)
    }

    // MARK: - Invite State

    public func getInviteState() -> InviteState? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.inviteState.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(InviteState.self, from: data)
    }

    public func setInviteState(_ state: InviteState) {
        guard let defaults = defaults,
              let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: AppGroupStorageKey.inviteState.rawValue)
        notifyUpdate(forKey: .inviteState)
    }

    public func incrementInviteCountLocal() {
        guard let current = getInviteState() else { return }
        let updated = InviteState(
            inviterId: current.inviterId,
            inviteCode: current.inviteCode,
            inviteLink: current.inviteLink,
            inviteCount: current.inviteCount + 1,
            lastRefreshAt: current.lastRefreshAt
        )
        setInviteState(updated)
    }

    // MARK: - Onboarding State

    public func getOnboardingState() -> OnboardingState? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.onboardingState.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(OnboardingState.self, from: data)
    }

    public func setOnboardingState(_ state: OnboardingState?) {
        guard let defaults = defaults else { return }
        if let state, let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: AppGroupStorageKey.onboardingState.rawValue)
        } else {
            defaults.removeObject(forKey: AppGroupStorageKey.onboardingState.rawValue)
        }
        notifyUpdate(forKey: .onboardingState)
    }

    public func getInviteAttribution() -> InviteAttribution? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.inviteAttribution.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(InviteAttribution.self, from: data)
    }

    public func setInviteAttribution(_ attribution: InviteAttribution?) {
        guard let defaults = defaults else { return }
        if let attribution, let data = try? JSONEncoder().encode(attribution) {
            defaults.set(data, forKey: AppGroupStorageKey.inviteAttribution.rawValue)
        } else {
            defaults.removeObject(forKey: AppGroupStorageKey.inviteAttribution.rawValue)
        }
        notifyUpdate(forKey: .inviteAttribution)
    }

    public func setLastAppOpenAt(_ date: Date?) {
        if let date = date {
            defaults?.set(date.timeIntervalSince1970, forKey: AppGroupStorageKey.lastAppOpenAt.rawValue)
        } else {
            defaults?.removeObject(forKey: AppGroupStorageKey.lastAppOpenAt.rawValue)
        }
        notifyUpdate(forKey: .lastAppOpenAt)
    }

    public func getLastAppOpenAt() -> Date? {
        let timestamp = defaults?.double(forKey: AppGroupStorageKey.lastAppOpenAt.rawValue) ?? 0
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // MARK: - Remote App Config
    
    public func getRemoteAppConfig() -> RemoteAppConfig? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.remoteAppConfig.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(RemoteAppConfig.self, from: data)
    }
    
    public func setRemoteAppConfig(_ config: RemoteAppConfig?) {
        guard let defaults = defaults else { return }
        if let config = config, let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: AppGroupStorageKey.remoteAppConfig.rawValue)
        } else {
            defaults.removeObject(forKey: AppGroupStorageKey.remoteAppConfig.rawValue)
        }
        notifyUpdate(forKey: .remoteAppConfig)
    }

    // MARK: - Lock Plans
    
    public func getLockPlans() -> [LockPlan] {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.lockPlans.rawValue),
              let plans = try? JSONDecoder().decode([LockPlan].self, from: data) else {
            return []
        }
        return plans
    }
    
    public func setLockPlans(_ plans: [LockPlan]) {
        guard let defaults = defaults,
              let data = try? JSONEncoder().encode(plans) else { return }
        defaults.set(data, forKey: AppGroupStorageKey.lockPlans.rawValue)
        notifyUpdate(forKey: .lockPlans)
    }
    
    // MARK: - Social Contracts
    
    public func getSocialContracts() -> [SocialContract] {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.socialContracts.rawValue),
              let contracts = try? JSONDecoder().decode([SocialContract].self, from: data) else {
            return []
        }
        return contracts
    }
    
    public func setSocialContracts(_ contracts: [SocialContract]) {
        guard let defaults = defaults,
              let data = try? JSONEncoder().encode(contracts) else { return }
        defaults.set(data, forKey: AppGroupStorageKey.socialContracts.rawValue)
        notifyUpdate(forKey: .socialContracts)
    }
    
    // MARK: - IOU Ledger
    
    public func getIOULedger() -> [IOULedgerEntry] {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.iouLedger.rawValue),
              let ledger = try? JSONDecoder().decode([IOULedgerEntry].self, from: data) else {
            return []
        }
        return ledger
    }
    
    public func setIOULedger(_ entries: [IOULedgerEntry]) {
        guard let defaults = defaults,
              let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: AppGroupStorageKey.iouLedger.rawValue)
        notifyUpdate(forKey: .iouLedger)
    }
    
    // MARK: - Shield State
    
    public func getShieldState() -> ShieldState? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroupStorageKey.shieldState.rawValue) else {
            return nil
        }
        return try? JSONDecoder().decode(ShieldState.self, from: data)
    }
    
    public func setShieldState(_ state: ShieldState?) {
        guard let defaults = defaults else { return }
        if let state = state, let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: AppGroupStorageKey.shieldState.rawValue)
        } else {
            defaults.removeObject(forKey: AppGroupStorageKey.shieldState.rawValue)
        }
        notifyUpdate(forKey: .shieldState)
    }
    
    // MARK: - Quorum State
    
    public func getQuorumState(sessionId: UUID) -> QuorumState? {
        guard let defaults = defaults else { return nil }
        let key = AppGroupStorageKey.quorumStateKey(for: sessionId)
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(QuorumState.self, from: data)
    }
    
    public func setQuorumState(_ state: QuorumState?, sessionId: UUID) {
        guard let defaults = defaults else { return }
        let key = AppGroupStorageKey.quorumStateKey(for: sessionId)
        if let state = state, let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
        notifyUpdate(forKey: .shieldState)
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
