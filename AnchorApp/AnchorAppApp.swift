import SwiftUI
import UIKit

// MARK: - App Delegate for APNs
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register for remote notifications
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Forward token to NotificationService
        Task {
            do {
                try await NotificationService.shared.registerDeviceToken(deviceToken)
            } catch {
                // Log error - token registration failed
                print("Failed to register device token: \(error)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Log error - APNs registration failed
        print("Failed to register for remote notifications: \(error)")
    }
}

@main
struct AnchorAppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}

