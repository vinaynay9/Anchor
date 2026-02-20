import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings
import Shared

/// Service for managing scheduled blocking via DeviceActivityMonitor
class DeviceActivityService {
    static let shared = DeviceActivityService()
    
    private let center = DeviceActivityCenter()
    private let appGroupStorage = AppGroupStorage.shared
    private let screenTimeService: ScreenTimeServiceProtocol
    
    // Store active schedules keyed by session ID
    private var activeSchedules: [UUID: DeviceActivityName] = [:]
    
    private init(screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared) {
        self.screenTimeService = screenTimeService
    }
    
    // MARK: - Schedule Management

    /// Schedules the daily anchor window to begin at the given local time.
    /// This is a simple, repeating schedule that starts daily and ends at 23:59.
    func scheduleDailyAnchor(startTime: DailyAnchorTime) throws {
        guard screenTimeService.isAuthorized() else {
            throw DeviceActivityError.authorizationDenied
        }

        let activityName = DeviceActivityName("daily_anchor")
        let startComponents = DateComponents(hour: startTime.hour, minute: startTime.minute)
        let endComponents = DateComponents(hour: 23, minute: 59)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )

        do {
            try center.startMonitoring(activityName, during: schedule)
            LoggerService.shared.logInfo("Scheduled daily anchor at \(startTime.hour):\(startTime.minute)", category: "DeviceActivity")
        } catch {
            LoggerService.shared.logError("Failed to schedule daily anchor", error: error, category: "DeviceActivity")
            throw DeviceActivityError.scheduleFailed(error)
        }
    }

    func cancelDailyAnchor() {
        let activityName = DeviceActivityName("daily_anchor")
        center.stopMonitoring([activityName])
    }
    
    /// Schedules a session to start and end at specific times.
    /// Creates separate schedules for each selected weekday since DeviceActivitySchedule only supports one weekday per schedule.
    /// - Parameters:
    ///   - session: The session to schedule
    ///   - schedule: The schedule configuration
    func scheduleSession(_ session: LockSession, schedule: LockSessionSchedule) throws {
        guard screenTimeService.isAuthorized() else {
            throw DeviceActivityError.authorizationDenied
        }
        
        guard !schedule.weekdays.isEmpty else {
            throw DeviceActivityError.invalidSchedule
        }
        
        // Store session metadata for intervalDidStart to use
        saveScheduledSessionMetadata(session)
        
        // Store the schedule configuration in AppGroup storage
        saveScheduleConfiguration(session.id, schedule: schedule)
        
        // LockSessionSchedule.weekdays uses: 1=Sunday, 2=Monday, ..., 7=Saturday
        // Calendar.weekday uses: 1=Sunday, 2=Monday, ..., 7=Saturday (same format!)
        // So no conversion needed - use weekday directly
        
        // DeviceActivitySchedule only supports one weekday per schedule.
        // For multiple weekdays, we create separate activity names (one per weekday).
        let sortedWeekdays = schedule.weekdays.sorted()
        var scheduledActivities: [DeviceActivityName] = []
        var errors: [(weekday: Int, error: Error)] = []
        
        for weekday in sortedWeekdays {
            // Create a unique activity name for this session + weekday combination
            let activityName = DeviceActivityName("session_\(session.id.uuidString)_wd\(weekday)")
            
            var startComponents = schedule.startTime.dateComponents
            var endComponents = schedule.endTime.dateComponents
            startComponents.weekday = weekday
            endComponents.weekday = weekday
            
            let deviceSchedule = DeviceActivitySchedule(
                intervalStart: startComponents,
                intervalEnd: endComponents,
                repeats: true
            )
            
            do {
                try center.startMonitoring(activityName, during: deviceSchedule)
                scheduledActivities.append(activityName)
                LoggerService.shared.logInfo("Scheduled session \(session.id.uuidString) for weekday \(weekday)", category: "DeviceActivity")
            } catch {
                LoggerService.shared.logError("Failed to schedule session \(session.id.uuidString) for weekday \(weekday)", error: error, category: "DeviceActivity")
                errors.append((weekday: weekday, error: error))
            }
        }
        
        // Store all scheduled activities for this session
        if !scheduledActivities.isEmpty {
            saveActiveSchedules(session.id, activities: scheduledActivities)
            LoggerService.shared.logInfo("Successfully scheduled session \(session.id.uuidString) for \(scheduledActivities.count) weekdays", category: "DeviceActivity")
        }
        
        // If all schedules failed, throw error
        if scheduledActivities.isEmpty && !errors.isEmpty {
            throw DeviceActivityError.scheduleFailed(errors.first!.error)
        }
        
        // If some schedules failed but at least one succeeded, log warning but continue
        if !errors.isEmpty {
            LoggerService.shared.logWarning("Session \(session.id.uuidString) partially scheduled: \(errors.count) weekdays failed", category: "DeviceActivity")
        }
    }
    
    /// Saves all active schedules for a session (multiple weekdays).
    private func saveActiveSchedules(_ sessionId: UUID, activities: [DeviceActivityName]) {
        let key = "activeSchedules_\(sessionId.uuidString)"
        let activityNames = activities.map { $0.rawValue }
        UserDefaults(suiteName: AppGroupStorage.appGroupIdentifier)?.set(activityNames, forKey: key)
    }
    
    /// Loads active schedule activity names for a session.
    private func loadActiveSchedules(_ sessionId: UUID) -> [DeviceActivityName] {
        let key = "activeSchedules_\(sessionId.uuidString)"
        guard let activityNames = UserDefaults(suiteName: AppGroupStorage.appGroupIdentifier)?.array(forKey: key) as? [String] else {
            return []
        }
        return activityNames.map { DeviceActivityName($0) }
    }
    
    /// Clears active schedule storage for a session.
    private func clearActiveSchedules(_ sessionId: UUID) {
        let key = "activeSchedules_\(sessionId.uuidString)"
        UserDefaults(suiteName: AppGroupStorage.appGroupIdentifier)?.removeObject(forKey: key)
    }
    
    /// Cancels a scheduled session and all its weekday schedules.
    /// - Parameter sessionId: The ID of the session to cancel
    func cancelScheduledSession(sessionId: UUID) {
        // Load all activity names for this session (multiple weekdays)
        let activities = loadActiveSchedules(sessionId)
        
        if activities.isEmpty {
            // Try legacy single activity name format
            let legacyActivityName = DeviceActivityName("session_\(sessionId.uuidString)")
            center.stopMonitoring([legacyActivityName])
        } else {
            // Stop all weekday schedules
            center.stopMonitoring(activities)
        }
        
        // Clear all related storage
        activeSchedules.removeValue(forKey: sessionId)
        clearActiveSchedules(sessionId)
        clearScheduleConfiguration(sessionId)
        clearScheduledSessionMetadata(sessionId)
        
        LoggerService.shared.logInfo("Cancelled scheduled session \(sessionId.uuidString) and all weekday schedules", category: "DeviceActivity")
    }
    
    private func clearScheduledSessionMetadata(_ sessionId: UUID) {
        let key = AppGroupStorageKey.scheduledSessionMetadataKey(for: sessionId)
        UserDefaults(suiteName: AppGroupStorage.appGroupIdentifier)?.removeObject(forKey: key)
    }
    
    // MARK: - Schedule Configuration Storage
    
    private func saveScheduleConfiguration(_ sessionId: UUID, schedule: LockSessionSchedule) {
        // Store schedule in AppGroup storage for the monitor to access
        let key = AppGroupStorageKey.scheduledSessionConfigurationKey(for: sessionId)
        if let encoded = try? JSONEncoder().encode(schedule),
           let jsonString = String(data: encoded, encoding: .utf8) {
            UserDefaults(suiteName: AppGroupStorage.appGroupIdentifier)?.set(jsonString, forKey: key)
        }
    }
    
    private func clearScheduleConfiguration(_ sessionId: UUID) {
        let key = AppGroupStorageKey.scheduledSessionConfigurationKey(for: sessionId)
        UserDefaults(suiteName: AppGroupStorage.appGroupIdentifier)?.removeObject(forKey: key)
    }
    
    func loadScheduleConfiguration(_ sessionId: UUID) -> LockSessionSchedule? {
        let key = AppGroupStorageKey.scheduledSessionConfigurationKey(for: sessionId)
        guard let jsonString = UserDefaults(suiteName: AppGroupStorage.appGroupIdentifier)?.string(forKey: key),
              let data = jsonString.data(using: .utf8),
              let schedule = try? JSONDecoder().decode(LockSessionSchedule.self, from: data) else {
            return nil
        }
        return schedule
    }
    
    // MARK: - Scheduled Session Metadata Storage
    
    /// Stores session metadata needed to recreate the session when schedule fires
    private func saveScheduledSessionMetadata(_ session: LockSession) {
        struct ScheduledSessionMetadata: Codable {
            let durationMinutes: Int
            let friendIds: [String]
            let categories: [AppCategory]?
        }
        
        // Load friendIds from AppGroup storage (they should be saved when scheduleSession is called)
        let friendIds = appGroupStorage.loadCurrentSessionFriendIds()
        
        let metadata = ScheduledSessionMetadata(
            durationMinutes: session.schedule?.durationMinutes ?? 30,
            friendIds: friendIds,
            categories: session.selectedCategories
        )
        
        let key = AppGroupStorageKey.scheduledSessionMetadataKey(for: session.id)
        if let encoded = try? JSONEncoder().encode(metadata),
           let jsonString = String(data: encoded, encoding: .utf8) {
            UserDefaults(suiteName: AppGroupStorage.appGroupIdentifier)?.set(jsonString, forKey: key)
        }
    }
    
    func loadScheduledSessionMetadata(_ sessionId: UUID) -> (durationMinutes: Int, friendIds: [String], categories: [AppCategory]?)? {
        struct ScheduledSessionMetadata: Codable {
            let durationMinutes: Int
            let friendIds: [String]
            let categories: [AppCategory]?
        }
        
        let key = AppGroupStorageKey.scheduledSessionMetadataKey(for: sessionId)
        guard let jsonString = UserDefaults(suiteName: AppGroupStorage.appGroupIdentifier)?.string(forKey: key),
              let data = jsonString.data(using: .utf8),
              let metadata = try? JSONDecoder().decode(ScheduledSessionMetadata.self, from: data) else {
            return nil
        }
        return (metadata.durationMinutes, metadata.friendIds, metadata.categories)
    }
}

// MARK: - Device Activity Monitor

/// Monitor that handles scheduled blocking intervals
class AnchorDeviceActivityMonitor: DeviceActivityMonitor {
    private let screenTimeService: ScreenTimeServiceProtocol
    private let appGroupStorage = AppGroupStorage.shared
    private let deviceActivityService = DeviceActivityService.shared
    
    override init() {
        self.screenTimeService = ScreenTimeService.shared
        super.init()
    }
    
    /// Called when a scheduled interval starts
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        if activity.rawValue == "daily_anchor" {
            Task {
                await screenTimeService.applyDailyAnchor()
                AppGroupStorage.shared.setShieldState(ShieldState(reason: .activeLock))
            }
            return
        }

        // Extract session ID from activity name
        guard let sessionId = extractSessionId(from: activity) else {
            LoggerService.shared.logWarning("Could not extract session ID from activity \(activity.rawValue)", category: "DeviceActivity")
            return
        }
        
        // Load session configuration
        guard let schedule = deviceActivityService.loadScheduleConfiguration(sessionId) else {
            LoggerService.shared.logWarning("Could not load schedule configuration for session \(sessionId.uuidString)", category: "DeviceActivity")
            return
        }
        
        // Load session metadata (duration, friends, categories)
        guard let metadata = deviceActivityService.loadScheduledSessionMetadata(sessionId) else {
            LoggerService.shared.logWarning("Could not load session metadata for session \(sessionId.uuidString)", category: "DeviceActivity")
            return
        }
        
        LoggerService.shared.logInfo("Interval started for session \(sessionId.uuidString)", category: "DeviceActivity")
        
        // Create the session via SessionService
        Task {
            do {
                let sessionService = SessionService.shared
                let session = try await sessionService.startSession(
                    durationMinutes: metadata.durationMinutes,
                    friendIds: metadata.friendIds,
                    categories: metadata.categories,
                    schedule: nil // Don't schedule again - this IS the scheduled start
                )
                LoggerService.shared.logInfo("Created session \(session.id.uuidString) from scheduled interval", category: "DeviceActivity")
            } catch {
                LoggerService.shared.logError("Failed to create session from scheduled interval", error: error, category: "DeviceActivity")
                // Still try to start blocking even if session creation fails
                await screenTimeService.startBlockingForScheduledSession(
                    sessionId: sessionId,
                    categories: metadata.categories,
                    schedule: schedule
                )
            }
        }
    }
    
    /// Called when a scheduled interval ends
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        if activity.rawValue == "daily_anchor" {
            Task { await screenTimeService.stopBlocking() }
            return
        }
        
        // Extract session ID from activity name
        guard let sessionId = extractSessionId(from: activity) else {
            return
        }
        
        LoggerService.shared.logInfo("Interval ended for session \(sessionId.uuidString)", category: "DeviceActivity")
        // Stop blocking
        Task {
            await screenTimeService.stopBlocking()
        }
    }
    
    /// Called when an event threshold is reached
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // Handle threshold events if needed (e.g., time limits)
    }
    
    // MARK: - Helpers
    
    /// Extracts the session ID from an activity name.
    /// Handles both legacy format (session_UUID) and new format (session_UUID_wdX).
    private func extractSessionId(from activity: DeviceActivityName) -> UUID? {
        let activityString = activity.rawValue
        
        guard activityString.hasPrefix("session_") else {
            return nil
        }
        
        // Remove "session_" prefix
        var uuidPart = String(activityString.dropFirst("session_".count))
        
        // Check for weekday suffix (e.g., "_wd1" for Sunday)
        // New format: session_UUID_wdX where X is weekday number
        if let weekdaySuffixRange = uuidPart.range(of: "_wd\\d+$", options: .regularExpression) {
            uuidPart = String(uuidPart[..<weekdaySuffixRange.lowerBound])
        }
        
        return UUID(uuidString: uuidPart)
    }
}

// MARK: - Errors

enum DeviceActivityError: LocalizedError {
    case authorizationDenied
    case scheduleFailed(Error)
    case invalidSchedule
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Screen Time authorization is required for scheduled blocking"
        case .scheduleFailed(let error):
            return "Failed to schedule session: \(error.localizedDescription)"
        case .invalidSchedule:
            return "Invalid schedule configuration"
        }
    }
}
