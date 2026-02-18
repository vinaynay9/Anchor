import Foundation
import FamilyControls
import Shared

enum ScreenTimeAuthorizationStatus {
    case notDetermined
    case denied
    case restricted
    case approved
}

protocol ScreenTimeServiceProtocol {
    func requestAuthorization() async throws
    func getAuthorizationStatus() -> ScreenTimeAuthorizationStatus
    func isAuthorized() -> Bool

    func applyBlockingFromStorage()
    func applyBlocking(selection: V0AppSelection)
    func applyTemporaryAllowance(allowedApplications: Set<ApplicationToken>)
    func clearBlocking()
}
