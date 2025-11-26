import Foundation
import Shared

// MARK: - Mock Screen Time Service
// This implementation works in simulator and doesn't require real Screen Time entitlements

class MockScreenTimeService: ScreenTimeServiceProtocol {
    static let shared = MockScreenTimeService()
    
    private var isBlocking: Bool = false
    private var authorizationStatus: ScreenTimeAuthorizationStatus = .notDetermined
    private var currentSession: LockSession?
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        // Simulate authorization request
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        // For mock, always approve
        authorizationStatus = .approved
    }
    
    func getAuthorizationStatus() -> ScreenTimeAuthorizationStatus {
        return authorizationStatus
    }
    
    func isAuthorized() -> Bool {
        return authorizationStatus == .approved
    }
    
    // MARK: - Blocking Control
    
    func startBlocking(for session: LockSession) async {
        // Simulate blocking delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        
        isBlocking = true
        currentSession = session
        
        // Log for debugging
        print("🔒 MockScreenTimeService: Started blocking for session \(session.id)")
        print("   - Duration: \(session.endTime?.timeIntervalSince(session.startTime) ?? 0) seconds")
        print("   - Apps blocked: \(session.appsBlocked.count)")
    }
    
    func stopBlocking() async {
        // Simulate unblocking delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        
        isBlocking = false
        currentSession = nil
        
        // Log for debugging
        print("🔓 MockScreenTimeService: Stopped blocking")
    }
    
    // MARK: - Additional Mock Helpers (for testing)
    
    var isCurrentlyBlocking: Bool {
        return isBlocking
    }
    
    var activeSession: LockSession? {
        return currentSession
    }
    
    func reset() {
        isBlocking = false
        currentSession = nil
        authorizationStatus = .notDetermined
    }
}

