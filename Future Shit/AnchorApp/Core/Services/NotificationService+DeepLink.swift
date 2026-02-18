import Foundation
import UserNotifications

extension NotificationService {
    /// Handle deep link navigation for unlock request notifications
    /// Returns the unlock request ID if found, nil otherwise
    func extractUnlockRequestId(from notification: UNNotification) -> UUID? {
        let userInfo = notification.request.content.userInfo
        
        if let unlockRequestId = userInfo["unlock_request_id"] as? String,
           let uuid = UUID(uuidString: unlockRequestId) {
            return uuid
        }
        
        return nil
    }
}

