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
    
    // MARK: - SessionServiceProtocol Implementation
    
    func startSession(
        durationMinutes: Int,
        friendIds: [String],
        categories: [AppCategory]? = nil,
        schedule: LockSessionSchedule? = nil
    ) async throws -> LockSession {
        if let error = shouldThrowError {
            throw error
        }
        
        startSessionCalled = true
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
            schedule: schedule
        )
        
        activeSession = session
        return session
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
    
    func cancelScheduledSession(sessionId: UUID) async throws {
        if let error = shouldThrowError {
            throw error
        }
        
        cancelScheduledSessionCalled = true
        lastCancelledSessionId = sessionId
        scheduledSessions.removeValue(forKey: sessionId)
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

