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
    private let lastTokenSentKey = "lastDeviceTokenSent"
    
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
        // Get AppDelegate instance
        guard let appDelegate = AppDelegate.shared else {
            throw NotificationError.registrationFailed
        }
        
        // Request authorization and register for push notifications via AppDelegate
        // AppDelegate handles authorization, registration, and returns the device token
        let deviceToken = try await appDelegate.registerForPushNotifications()
        
        // Token is already sent to backend by AppDelegate in didRegisterForRemoteNotificationsWithDeviceToken
        // Return the token string
        return deviceToken
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
    
    // MARK: - Device Token Registration
    func registerDeviceToken(_ token: Data) async throws {
        // Convert token Data to hex string
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Check if we've already sent this token to prevent duplicates
        let lastTokenSent = UserDefaults.standard.string(forKey: lastTokenSentKey)
        if lastTokenSent == tokenString {
            return // Token already registered
        }
        
        // POST to backend
        try await apiClient.request(.registerDeviceToken(token: tokenString))
        
        // Store the token we just sent
        UserDefaults.standard.set(tokenString, forKey: lastTokenSentKey)
    }
    
    // MARK: - Notification Preferences
    func updateNotificationPreferences() async throws {
        // Optional: Implement later to sync notification preferences with backend
        // This could include settings like:
        // - Enable/disable unlock request notifications
        // - Enable/disable session reminder notifications
        // - Quiet hours settings
        // etc.
    }
}

