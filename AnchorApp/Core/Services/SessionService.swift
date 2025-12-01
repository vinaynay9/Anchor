import Foundation
import Shared

protocol SessionServiceProtocol {
    func startSession(durationMinutes: Int, friendIds: [String]) async throws -> LockSession
    func endSession() async throws
    func getActiveSession() async throws -> LockSession?
}

class SessionService: SessionServiceProtocol {
    static let shared = SessionService()
    
    private let appGroupStorage = AppGroupStorage.shared
    private let screenTimeService: ScreenTimeServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var activeSession: LockSession?
    private var timer: Timer?
    private let userId: UUID
    
    // Store friendIds separately since LockSession only has accountabilityPartnerId
    private var currentFriendIds: [String] = []
    
    init(
        screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared,
        notificationService: NotificationServiceProtocol = NotificationService.shared
    ) {
        self.screenTimeService = screenTimeService
        self.notificationService = notificationService
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
        
        activeSession = LockSession(
            id: UUID(), // Generate new ID for restored session
            userId: userId,
            status: .active,
            startTime: startTime,
            endTime: endTime,
            appsBlocked: [],
            accountabilityPartnerId: accountabilityPartnerId,
            createdAt: startTime
        )
        
        // Restart timer
        startTimer()
    }
    
    // MARK: - Protocol Implementation
    
    func startSession(durationMinutes: Int, friendIds: [String]) async throws -> LockSession {
        // End any existing active session
        if activeSession != nil {
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
        
        // Create session
        let session = LockSession(
            id: UUID(),
            userId: userId,
            status: .active,
            startTime: startTime,
            endTime: endTime,
            appsBlocked: [],
            accountabilityPartnerId: accountabilityPartnerId,
            createdAt: Date()
        )
        
        // POST /sessions/start
        let apiClient = APIClient.shared
        let dto: LockSessionDTO = try await apiClient.request(.startSession(session: session), responseType: LockSessionDTO.self)
        
        guard let createdSession = dto.toLockSession() else {
            throw AnchorAPIError.decodingError(NSError(domain: "SessionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode session from API"]))
        }
        
        activeSession = createdSession
        
        // Write to AppGroupStorage
        let sharedState = SharedSessionState(
            isActive: true,
            endTime: endTime,
            remainingSeconds: remainingSeconds
        )
        appGroupStorage.setSessionState(sharedState)
        
        // Integrate with ScreenTimeService to block apps
        await screenTimeService.startBlocking(for: createdSession)
        
        // Start timer
        startTimer()
        
        return createdSession
    }
    
    func endSession() async throws {
        guard let session = activeSession else {
            return // No active session to end
        }
        
        // POST /sessions/end
        let apiClient = APIClient.shared
        do {
            try await apiClient.request(.endSession(sessionId: session.id))
        } catch {
            // Continue with local cleanup even if API call fails
        }
        
        // Clear AppGroupStorage
        appGroupStorage.setSessionState(nil)
        
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
        
        // Send notification that session ended
        await notificationService.notifySessionEnded()
    }
    
    func getActiveSession() async throws -> LockSession? {
        // GET /sessions/active
        let apiClient = APIClient.shared
        
        do {
            let dto: LockSessionDTO? = try await apiClient.request(.getActiveSession, responseType: LockSessionDTO?.self)
            
            if let dto = dto, let session = dto.toLockSession() {
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
            Task {
                // Send notification that session expired before ending
                await notificationService.notifySessionExpired()
                try? await endSession()
            }
        }
    }
}

