import Foundation
import Shared

/// Mock implementation of SessionServiceProtocol for testing.
/// Allows injection of predefined session state and error conditions.
final class MockSessionService: SessionServiceProtocol {
    var activeSession: LockSession?
    var shouldThrowError: Error?
    var startSessionCalled = false
    var endSessionCalled = false
    var getActiveSessionCalled = false
    
    func startSession(durationMinutes: Int, friendIds: [String]) async throws -> LockSession {
        if let error = shouldThrowError {
            throw error
        }
        startSessionCalled = true
        
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
            createdAt: startTime
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
    
    func reset() {
        activeSession = nil
        shouldThrowError = nil
        startSessionCalled = false
        endSessionCalled = false
        getActiveSessionCalled = false
    }
}

