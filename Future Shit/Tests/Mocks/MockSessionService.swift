import Foundation
import Shared

/// Mock implementation of SessionServiceProtocol for testing.
/// Allows injection of predefined session state and error conditions.
final class MockSessionService: SessionServiceProtocol {
    // MARK: - State
    var activeSession: LockSession?
    var scheduledSessions: [UUID: LockSession] = [:]
    
    // MARK: - Error Simulation
    var shouldThrowError: Error?
    
    // MARK: - Call Tracking
    var startSessionCalled = false
    var endSessionCalled = false
    var getActiveSessionCalled = false
    var scheduleSessionCalled = false
    var cancelScheduledSessionCalled = false
    
    // MARK: - Last Call Parameters (for assertions)
    var lastStartSessionDuration: Int?
    var lastStartSessionFriendIds: [String]?
    var lastStartSessionCategories: [AppCategory]?
    var lastStartSessionSchedule: LockSessionSchedule?
    var lastCancelledSessionId: UUID?
    var lastStartSessionPlan: LockPlan?
    
    // MARK: - SessionServiceProtocol Implementation
    
    func startSession(from plan: LockPlan, durationMinutes: Int, friendIds: [String], categories: [AppCategory]? = nil, schedule: LockSessionSchedule? = nil) async throws -> LockSession {
        if let error = shouldThrowError {
            throw error
        }
        
        startSessionCalled = true
        lastStartSessionPlan = plan
        lastStartSessionDuration = durationMinutes
        lastStartSessionFriendIds = friendIds
        lastStartSessionCategories = categories
        lastStartSessionSchedule = schedule
        
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(Double(durationMinutes) * 60)
        let accountabilityPartnerId = friendIds.first.flatMap { UUID(uuidString: $0) }
        
        let session = LockSession(
            id: UUID(),
            userId: UUID(),
            status: .active,
            startTime: startTime,
            endTime: endTime,
            appsBlocked: [],
            accountabilityPartnerId: accountabilityPartnerId,
            createdAt: startTime,
            selectedCategories: categories,
            schedule: schedule,
            lockPlanId: plan.id,
            lockPlanType: plan.type,
            lockMode: plan.mode,
            unlockPolicy: plan.unlockPolicy,
            goalRequirement: plan.goalRequirement,
            quorumState: nil
        )
        
        activeSession = session
        return session
    }
    
    func startSession(
        durationMinutes: Int,
        friendIds: [String],
        categories: [AppCategory]? = nil,
        schedule: LockSessionSchedule? = nil
    ) async throws -> LockSession {
        let fallbackPlan = LockPlan(name: "Custom Lock", type: .custom)
        return try await startSession(
            from: fallbackPlan,
            durationMinutes: durationMinutes,
            friendIds: friendIds,
            categories: categories,
            schedule: schedule
        )
    }
    
    func endSession() async throws {
        if let error = shouldThrowError {
            throw error
        }
        endSessionCalled = true
        activeSession = nil
    }
    
    func getActiveSession() async throws -> LockSession? {
        if let error = shouldThrowError {
            throw error
        }
        getActiveSessionCalled = true
        return activeSession
    }
    
    func scheduleSession(
        durationMinutes: Int,
        friendIds: [String],
        categories: [AppCategory]?,
        schedule: LockSessionSchedule
    ) async throws -> LockSession {
        if let error = shouldThrowError {
            throw error
        }
        
        scheduleSessionCalled = true
        lastStartSessionDuration = durationMinutes
        lastStartSessionFriendIds = friendIds
        lastStartSessionCategories = categories
        lastStartSessionSchedule = schedule
        
        let session = LockSession(
            id: UUID(),
            userId: UUID(),
            status: .active,
            startTime: Date(),
            endTime: nil, // Scheduled sessions don't have end time until activated
            appsBlocked: [],
            accountabilityPartnerId: friendIds.first.flatMap { UUID(uuidString: $0) },
            createdAt: Date(),
            selectedCategories: categories,
            schedule: schedule
        )
        
        scheduledSessions[session.id] = session
        return session
    }
    
    func scheduleSession(from plan: LockPlan, durationMinutes: Int, friendIds: [String], categories: [AppCategory]?, schedule: LockSessionSchedule) async throws -> LockSession {
        let session = try await scheduleSession(
            durationMinutes: durationMinutes,
            friendIds: friendIds,
            categories: categories,
            schedule: schedule
        )
        return LockSession(
            id: session.id,
            userId: session.userId,
            status: session.status,
            startTime: session.startTime,
            endTime: session.endTime,
            appsBlocked: session.appsBlocked,
            accountabilityPartnerId: session.accountabilityPartnerId,
            createdAt: session.createdAt,
            selectedCategories: session.selectedCategories,
            schedule: session.schedule,
            lockPlanId: plan.id,
            lockPlanType: plan.type,
            lockMode: plan.mode,
            unlockPolicy: plan.unlockPolicy,
            goalRequirement: plan.goalRequirement,
            quorumState: nil,
            events: session.events
        )
    }
    
    func cancelScheduledSession(sessionId: UUID) async throws {
        if let error = shouldThrowError {
            throw error
        }
        
        cancelScheduledSessionCalled = true
        lastCancelledSessionId = sessionId
        scheduledSessions.removeValue(forKey: sessionId)
    }
    
    func extendActiveSession(byMinutes minutes: Int) async {
        guard var session = activeSession, minutes > 0 else { return }
        if let endTime = session.endTime {
            session = LockSession(
                id: session.id,
                userId: session.userId,
                status: session.status,
                startTime: session.startTime,
                endTime: endTime.addingTimeInterval(TimeInterval(minutes * 60)),
                appsBlocked: session.appsBlocked,
                accountabilityPartnerId: session.accountabilityPartnerId,
                createdAt: session.createdAt,
                selectedCategories: session.selectedCategories,
                schedule: session.schedule,
                lockPlanId: session.lockPlanId,
                lockPlanType: session.lockPlanType,
                lockMode: session.lockMode,
                unlockPolicy: session.unlockPolicy,
                goalRequirement: session.goalRequirement,
                quorumState: session.quorumState,
                events: session.events
            )
            activeSession = session
        }
    }
    
    func handleQuorumReached(sessionId: UUID) async {
        if activeSession?.id == sessionId {
            activeSession = nil
        }
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        activeSession = nil
        scheduledSessions = [:]
        shouldThrowError = nil
        startSessionCalled = false
        endSessionCalled = false
        getActiveSessionCalled = false
        scheduleSessionCalled = false
        cancelScheduledSessionCalled = false
        lastStartSessionDuration = nil
        lastStartSessionFriendIds = nil
        lastStartSessionCategories = nil
        lastStartSessionSchedule = nil
        lastCancelledSessionId = nil
        lastStartSessionPlan = nil
    }
    
    /// Sets up a mock active session for testing
    func setMockActiveSession(durationMinutes: Int = 25, friendIds: [String] = []) {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(Double(durationMinutes) * 60)
        
        activeSession = LockSession(
            id: UUID(),
            userId: UUID(),
            status: .active,
            startTime: startTime,
            endTime: endTime,
            appsBlocked: [],
            accountabilityPartnerId: friendIds.first.flatMap { UUID(uuidString: $0) },
            createdAt: startTime
        )
    }
}
