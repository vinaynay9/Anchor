import Foundation
import Shared

// MARK: - Screen Time Authorization Status
enum ScreenTimeAuthorizationStatus {
    case notDetermined
    case denied
    case restricted  // Note: .restricted means controlled by parental controls/MDM, NOT same as .notDetermined
    case approved
}

// MARK: - Screen Time Service Protocol
// This protocol allows us to inject a mock implementation for testing/simulator
protocol ScreenTimeServiceProtocol {
    /// Requests FamilyControls authorization.
    /// Throws ScreenTimeError on failure with specific reason.
    func requestAuthorization() async throws
    
    /// Gets the current authorization status.
    /// Properly handles .restricted (does NOT treat as .notDetermined).
    func getAuthorizationStatus() -> ScreenTimeAuthorizationStatus
    
    /// Starts blocking apps for the given session.
    /// Uses app/category tokens from the session and ActivitySelectionService.
    func startBlocking(for session: LockSession) async
    
    /// Updates blocking for an existing session.
    /// Used when session configuration changes mid-session.
    func updateBlocking(for session: LockSession) async throws
    
    /// Stops all blocking and clears restrictions.
    func stopBlocking() async
    
    /// Synchronous check if authorized.
    func isAuthorized() -> Bool
    
    /// Starts blocking for a scheduled session (called by DeviceActivityMonitor).
    func startBlockingForScheduledSession(sessionId: UUID, categories: [AppCategory]?, schedule: LockSessionSchedule) async

    /// Applies the daily anchor blocking based on the user's schedule.
    func applyDailyAnchor() async

    /// Applies additional blocking based on active challenges.
    func applyChallengeOverrides() async

    /// Temporarily removes blocking for an emergency unanchor.
    func emergencyUnanchor(duration: TimeInterval) async
}
