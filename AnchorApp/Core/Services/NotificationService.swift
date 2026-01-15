import Foundation
import UserNotifications
import SwiftUI
import Shared

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
    func checkAuthorizationStatus() async -> Bool
    func notifyUnlockRequestApproved(requestId: String) async
    func notifyUnlockRequestRejected(requestId: String) async
    func notifySessionEnded() async
    func notifySessionExpired() async
    func notifyAnchorsEmergencyUnanchor(anchors: [Friend], reason: String, duration: TimeInterval) async
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
           UUID(uuidString: unlockRequestId) != nil {
            // Navigate to unlock request detail view using DeepLinkHandler
            // The deep link will be picked up by AppCoordinator which observes pendingDeepLink
            Task { @MainActor in
                let url = URL(string: "anchor://unlock-request/\(unlockRequestId)")!
                _ = DeepLinkHandler.shared.handleURL(url)
            }
            return true
        }
        
        // Check for session notification
        if let sessionId = userInfo["session_id"] as? String,
           UUID(uuidString: sessionId) != nil {
            Task { @MainActor in
                let url = URL(string: "anchor://session/\(sessionId)")!
                _ = DeepLinkHandler.shared.handleURL(url)
            }
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
    
    // MARK: - Authorization Status Check
    func checkAuthorizationStatus() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Unlock Request Notifications
    func notifyUnlockRequestApproved(requestId: String) async {
        let isAuthorized = await checkAuthorizationStatus()
        
        if isAuthorized {
            scheduleLocalNotification(
                title: "Unlock Request Approved",
                body: "Your unlock request has been approved. Apps are now accessible.",
                identifier: "unlock-request-approved-\(requestId)"
            )
        } else {
            // Fallback banner when notifications are disabled
            await MainActor.run {
                ToastManager.shared.showSuccess("Unlock Request Approved - Apps are now accessible")
            }
        }
    }
    
    func notifyUnlockRequestRejected(requestId: String) async {
        let isAuthorized = await checkAuthorizationStatus()
        
        if isAuthorized {
            scheduleLocalNotification(
                title: "Unlock Request Denied",
                body: "Your unlock request has been denied. Session continues.",
                identifier: "unlock-request-rejected-\(requestId)"
            )
        } else {
            // Fallback banner when notifications are disabled
            await MainActor.run {
                ToastManager.shared.showError("Unlock Request Denied - Session continues")
            }
        }
    }
    
    // MARK: - Session Event Notifications
    func notifySessionEnded() async {
        let isAuthorized = await checkAuthorizationStatus()
        
        if isAuthorized {
            scheduleLocalNotification(
                title: "Session Ended",
                body: "Your lock session has ended. Apps are now accessible.",
                identifier: "session-ended-\(UUID().uuidString)"
            )
        } else {
            // Fallback banner when notifications are disabled
            await MainActor.run {
                ToastManager.shared.showSuccess("Session Ended - Apps are now accessible")
            }
        }
    }
    
    func notifySessionExpired() async {
        let isAuthorized = await checkAuthorizationStatus()
        
        if isAuthorized {
            scheduleLocalNotification(
                title: "Session Expired",
                body: "Your lock session has expired. Apps are now accessible.",
                identifier: "session-expired-\(UUID().uuidString)"
            )
        } else {
            // Fallback banner when notifications are disabled
            await MainActor.run {
                ToastManager.shared.showSuccess("Session Expired - Apps are now accessible")
            }
        }
    }

    func notifyAnchorsEmergencyUnanchor(anchors: [Friend], reason: String, duration: TimeInterval) async {
        let isAuthorized = await checkAuthorizationStatus()
        let anchorNames = anchors.map { $0.displayName ?? "Anchor" }
        let recipientSummary = anchorNames.isEmpty ? "your anchors" : anchorNames.joined(separator: ", ")
        let minutes = Int(duration / 60)
        
        if isAuthorized {
            scheduleLocalNotification(
                title: "Emergency Unanchor Sent",
                body: "Notified \(recipientSummary). Reason: \(reason). Duration: \(minutes) min.",
                identifier: "emergency-unanchor-\(UUID().uuidString)"
            )
        } else {
            await MainActor.run {
                ToastManager.shared.showWarning("Emergency unanchor sent to anchors.")
            }
        }
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
