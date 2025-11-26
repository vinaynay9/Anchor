import Foundation
import UserNotifications

enum NotificationError: Error {
    case notAuthorized
    case registrationFailed
    case invalidDeviceToken
}

protocol NotificationServiceProtocol {
    func requestAuthorization() async throws
    func registerForPushNotifications() async throws -> String
    func handleNotification(_ notification: UNNotification) -> Bool
    func scheduleLocalNotification(title: String, body: String, identifier: String)
}

class NotificationService: NotificationServiceProtocol {
    static let shared = NotificationService()
    
    private let apiClient = APIClient.shared
    
    // MARK: - Authorization
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        
        if !granted {
            throw NotificationError.notAuthorized
        }
    }
    
    // MARK: - Push Notification Registration
    func registerForPushNotifications() async throws -> String {
        // Request authorization first
        try await requestAuthorization()
        
        // Register with APNs
        // TODO: Implement APNs registration
        // This typically happens in AppDelegate or SceneDelegate
        // For SwiftUI, we can use UIApplicationDelegateAdaptor
        
        // For now, return a placeholder token
        // In production:
        // 1. Get device token from APNs
        // 2. Send token to backend via API
        // 3. Store token locally
        
        throw NotificationError.registrationFailed
    }
    
    // MARK: - Notification Handling
    func handleNotification(_ notification: UNNotification) -> Bool {
        let userInfo = notification.request.content.userInfo
        
        // Check if this is an unlock request notification
        if let unlockRequestId = userInfo["unlock_request_id"] as? String,
           let uuid = UUID(uuidString: unlockRequestId) {
            // TODO: Navigate to unlock request detail view
            // This should be handled by a coordinator or router
            return true
        }
        
        return false
    }
    
    // MARK: - Local Notifications
    func scheduleLocalNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

