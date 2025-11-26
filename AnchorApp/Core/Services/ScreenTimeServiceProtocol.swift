import Foundation
import Shared

// MARK: - Screen Time Authorization Status
enum ScreenTimeAuthorizationStatus {
    case notDetermined
    case denied
    case approved
}

// MARK: - Screen Time Service Protocol
// This protocol allows us to inject a mock implementation for testing/simulator
protocol ScreenTimeServiceProtocol {
    func requestAuthorization() async throws
    func getAuthorizationStatus() -> ScreenTimeAuthorizationStatus
    func startBlocking(for session: LockSession) async
    func stopBlocking() async
    func isAuthorized() -> Bool
}

