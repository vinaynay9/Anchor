import Foundation
import Shared

protocol SessionServiceProtocol {
    func startSession(durationMinutes: Int, friendIds: [String], categories: [AppCategory]?, schedule: LockSessionSchedule?) async throws -> LockSession
    func endSession() async throws
    func getActiveSession() async throws -> LockSession?
    func scheduleSession(durationMinutes: Int, friendIds: [String], categories: [AppCategory]?, schedule: LockSessionSchedule) async throws -> LockSession
    func cancelScheduledSession(sessionId: UUID) async throws
}

class SessionService: SessionServiceProtocol {
    static let shared = SessionService()
    
    private let appGroupStorage = AppGroupStorage.shared
    private let screenTimeService: ScreenTimeServiceProtocol
    private let deviceActivityService = DeviceActivityService.shared
    private let notificationService: NotificationServiceProtocol
    private let persistenceService = PersistenceService.shared
    private let analyticsService: AnalyticsServiceProtocol
    private var activeSession: LockSession?
    private var timer: Timer?
    private let userId: UUID
    
    // Store friendIds separately since LockSession only has accountabilityPartnerId
    private var currentFriendIds: [String] = []
    
    init(
        screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared,
        notificationService: NotificationServiceProtocol = NotificationService.shared,
        analyticsService: AnalyticsServiceProtocol = AnalyticsServiceProvider.shared
    ) {
        self.screenTimeService = screenTimeService
        self.notificationService = notificationService
        self.analyticsService = analyticsService
        // Get or create user ID
        if let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
           let uuid = UUID(uuidString: userIdString) {
            self.userId = uuid
        } else {
            self.userId = UUID()
            UserDefaults.standard.set(userId.uuidString, forKey: AppConfig.UserDefaultsKeys.currentUserId)
        }
        
        // Restore state on init
        restoreState()
    }
    
    // MARK: - State Restoration
    
    private func restoreState() {
        guard let sharedState = appGroupStorage.getSessionState(),
              sharedState.isActive,
              let endTime = sharedState.endTime else {
            return
        }
        
        // Check if session is still valid (not expired)
        guard endTime > Date() else {
            // Session expired, clear it
            Task {
                await notificationService.notifySessionExpired()
                try? await endSession()
            }
            return
        }
        
        // Rebuild session from stored state
        let startTime = endTime.addingTimeInterval(-Double(sharedState.remainingSeconds ?? 0))
        
        // Try to restore friendIds from AppGroup storage
        currentFriendIds = appGroupStorage.loadCurrentSessionFriendIds()
        
        let accountabilityPartnerId = currentFriendIds.first.flatMap { UUID(uuidString: $0) }
        
        // Generate a consistent session ID for restored session (use a stored ID or generate new)
        let restoredSessionId = UUID()
        
        var restoredSession = LockSession(
            id: restoredSessionId,
            userId: userId,
            status: .active,
            startTime: startTime,
            endTime: endTime,
            appsBlocked: [],
            accountabilityPartnerId: accountabilityPartnerId,
            createdAt: startTime,
            selectedCategories: nil,
            schedule: nil
        )
        
        // Load existing events
        let existingEvents = appGroupStorage.loadSessionEvents(forSessionId: restoredSessionId)
        restoredSession.events = existingEvents
        
        // If no events exist, add session started event (for restored sessions)
        if restoredSession.events.isEmpty {
            let startEvent = SessionEvent(type: .sessionStarted, timestamp: startTime)
            restoredSession.addEvent(startEvent)
            appGroupStorage.saveSessionEvents(restoredSession.events, forSessionId: restoredSessionId)
        }
        
        activeSession = restoredSession
        
        // Restart timer
        startTimer()
    }
    
    // MARK: - Protocol Implementation
    
    func startSession(durationMinutes: Int, friendIds: [String], categories: [AppCategory]? = nil, schedule: LockSessionSchedule? = nil) async throws -> LockSession {
        LoggerService.shared.logInfo("Starting session: duration=\(durationMinutes)min, friends=\(friendIds.count), categories=\(categories?.count ?? 0)", category: "Session")
        // End any existing active session
        if activeSession != nil {
            LoggerService.shared.logInfo("Ending existing session before starting new one", category: "Session")
            try await endSession()
        }
        
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(Double(durationMinutes) * 60)
        let remainingSeconds = durationMinutes * 60
        
        // Store friendIds in AppGroup storage
        currentFriendIds = friendIds
        appGroupStorage.saveCurrentSessionFriendIds(friendIds)
        
        // Convert friend IDs from String to UUID (use first one as accountabilityPartnerId)
        let accountabilityPartnerId = friendIds.first.flatMap { UUID(uuidString: $0) }
        
        // Create session with categories and schedule
        let session = LockSession(
            id: UUID(),
            userId: userId,
            status: .active,
            startTime: startTime,
            endTime: endTime,
            appsBlocked: [],
            accountabilityPartnerId: accountabilityPartnerId,
            createdAt: Date(),
            selectedCategories: categories,
            schedule: schedule
        )
        
        // If schedule is provided, schedule the session instead of starting immediately
        if let schedule = schedule {
            LoggerService.shared.logInfo("Scheduling session instead of starting immediately", category: "Session")
            return try await scheduleSession(durationMinutes: durationMinutes, friendIds: friendIds, categories: categories, schedule: schedule)
        }
        
        // POST /sessions/start
        LoggerService.shared.logInfo("Sending session start request to API", category: "Session")
        let apiClient = APIClient.shared
        let dto: LockSessionDTO = try await apiClient.request(.startSession(session: session), responseType: LockSessionDTO.self)
        
        guard let createdSession = dto.toLockSession() else {
            LoggerService.shared.logError("Failed to decode session from API", category: "Session")
            throw AnchorAPIError.decodingError(NSError(domain: "SessionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode session from API"]))
        }
        
        // Load existing events if any
        var sessionWithEvents = createdSession
        let existingEvents = appGroupStorage.loadSessionEvents(forSessionId: createdSession.id)
        sessionWithEvents.events = existingEvents
        
        // Add session started event
        let startEvent = SessionEvent(type: .sessionStarted, timestamp: startTime)
        sessionWithEvents.addEvent(startEvent)
        
        // Save events
        appGroupStorage.saveSessionEvents(sessionWithEvents.events, forSessionId: sessionWithEvents.id)
        
        LoggerService.shared.logInfo("Session created: \(sessionWithEvents.id.uuidString)", category: "Session")
        activeSession = sessionWithEvents
        
        // Persist session locally for offline support
        do {
            try persistenceService.saveSession(sessionWithEvents)
        } catch {
            LoggerService.shared.logError("Failed to persist session", error: error, category: "Session")
        }
        
        // Write to AppGroupStorage
        let sharedState = SharedSessionState(
            isActive: true,
            endTime: endTime,
            remainingSeconds: remainingSeconds
        )
        appGroupStorage.setSessionState(sharedState)
        
        analyticsService.log(
            event: .anchorStateChanged,
            payload: AnalyticsPayload(userState: .anchored)
        )
        
        // Integrate with ScreenTimeService to block apps
        await screenTimeService.startBlocking(for: sessionWithEvents)
        
        // Start timer
        startTimer()
        LoggerService.shared.logInfo("Session timer started", category: "Session")
        
        return sessionWithEvents
    }
    
    func scheduleSession(durationMinutes: Int, friendIds: [String], categories: [AppCategory]?, schedule: LockSessionSchedule) async throws -> LockSession {
        LoggerService.shared.logInfo("Scheduling session: duration=\(durationMinutes)min, schedule=\(schedule.weekdays)", category: "Session")
        // Create a session that will be scheduled (not started immediately)
        let sessionId = UUID()
        let accountabilityPartnerId = friendIds.first.flatMap { UUID(uuidString: $0) }
        
        // Store friendIds in AppGroup storage for the scheduled session
        // This will be retrieved when the schedule fires
        appGroupStorage.saveCurrentSessionFriendIds(friendIds)
        
        // Create session with scheduled status (we'll use a special status or handle it differently)
        let session = LockSession(
            id: sessionId,
            userId: userId,
            status: .active, // Will be activated when schedule fires
            startTime: Date(), // Placeholder, actual start will be when schedule fires
            endTime: nil, // Will be calculated when schedule fires
            appsBlocked: [],
            accountabilityPartnerId: accountabilityPartnerId,
            createdAt: Date(),
            selectedCategories: categories,
            schedule: schedule
        )
        
        // Schedule the session using DeviceActivityService
        do {
            try deviceActivityService.scheduleSession(session, schedule: schedule)
            LoggerService.shared.logInfo("Session scheduled successfully: \(sessionId.uuidString)", category: "Session")
        } catch {
            LoggerService.shared.logError("Failed to schedule session", error: error, category: "Session")
            throw error
        }
        
        // POST /sessions/start (with schedule info)
        let apiClient = APIClient.shared
        let dto: LockSessionDTO = try await apiClient.request(.startSession(session: session), responseType: LockSessionDTO.self)
        
        guard let createdSession = dto.toLockSession() else {
            throw AnchorAPIError.decodingError(NSError(domain: "SessionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode session from API"]))
        }
        
        // Don't set as activeSession since it's scheduled, not active yet
        // activeSession will be set when the schedule fires
        
        return createdSession
    }
    
    func cancelScheduledSession(sessionId: UUID) async throws {
        // Cancel the scheduled session
        deviceActivityService.cancelScheduledSession(sessionId: sessionId)
        
        // POST /sessions/cancel
        let apiClient = APIClient.shared
        try await apiClient.request(.endSession(sessionId: sessionId))
    }
    
    func endSession() async throws {
        guard var session = activeSession else {
            return // No active session to end
        }
        
        // Add session ended event
        let endEvent = SessionEvent(type: .sessionEnded, timestamp: Date())
        session.addEvent(endEvent)
        
        // Save events before ending
        appGroupStorage.saveSessionEvents(session.events, forSessionId: session.id)
        
        // POST /sessions/end
        let apiClient = APIClient.shared
        do {
            try await apiClient.request(.endSession(sessionId: session.id))
        } catch {
            // Continue with local cleanup even if API call fails
        }
        
        // Delete persisted session
        persistenceService.deleteSession(sessionId: session.id)
        
        // Clear AppGroupStorage
        appGroupStorage.setSessionState(nil)
        
        analyticsService.log(
            event: .anchorStateChanged,
            payload: AnalyticsPayload(userState: .free)
        )
        
        // Integrate with ScreenTimeService to unblock apps
        await screenTimeService.stopBlocking()
        
        // Stop timer
        stopTimer()
        
        // Clear pending unlock request if exists
        appGroupStorage.setPendingUnlockRequest(false)
        
        // Clear stored friendIds from AppGroup storage
        appGroupStorage.clearCurrentSessionFriendIds()
        currentFriendIds = []
        
        // Clear active session
        activeSession = nil
        LoggerService.shared.logInfo("Session ended and cleared", category: "Session")
        
        // Send notification that session ended
        await notificationService.notifySessionEnded()
    }
    
    /// Adds an event to the active session and persists it.
    /// - Parameter event: The event to add
    func addEventToActiveSession(_ event: SessionEvent) {
        guard var session = activeSession else { return }
        session.addEvent(event)
        appGroupStorage.saveSessionEvents(session.events, forSessionId: session.id)
        activeSession = session
    }
    
    func getActiveSession() async throws -> LockSession? {
        // GET /sessions/active
        let apiClient = APIClient.shared
        
        do {
            let dto: LockSessionDTO? = try await apiClient.request(.getActiveSession, responseType: LockSessionDTO?.self)
            
            if let dto = dto, var session = dto.toLockSession() {
                // Load events from storage
                let events = appGroupStorage.loadSessionEvents(forSessionId: session.id)
                session.events = events
                
                // Update local active session
                activeSession = session
                
                // Check if session has expired
                if let endTime = session.endTime, endTime <= Date() {
                    // Session expired, send notification and end it
                    await notificationService.notifySessionExpired()
                    try await endSession()
                    return nil
                }
                
                return session
            } else {
                // No active session from API
                activeSession = nil
                return nil
            }
        } catch {
            // If API call fails, check local session
            if let session = activeSession,
               let endTime = session.endTime,
               endTime <= Date() {
                // Session expired, send notification and clear it
                await notificationService.notifySessionExpired()
                try await endSession()
                return nil
            }
            
            return activeSession
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        stopTimer()
        
        // Ensure timer runs on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard let session = activeSession,
              let endTime = session.endTime else {
            stopTimer()
            return
        }
        
        let now = Date()
        let remainingSeconds = max(0, Int(endTime.timeIntervalSince(now)))
        
        // Update AppGroupStorage
        appGroupStorage.updateRemainingSeconds(remainingSeconds)
        
        // If session expired, end it
        if remainingSeconds <= 0 {
            LoggerService.shared.logInfo("Session expired, ending session", category: "Session")
            Task {
                // Send notification that session expired before ending
                await notificationService.notifySessionExpired()
                try? await endSession()
            }
        }
    }
}
