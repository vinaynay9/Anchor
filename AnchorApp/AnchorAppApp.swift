import SwiftUI
import UIKit
import UserNotifications
import Shared

// MARK: - App Delegate for APNs
class AppDelegate: NSObject, UIApplicationDelegate {
    static var shared: AppDelegate?
    
    private var tokenContinuation: CheckedContinuation<String, Error>?
    private let tokenContinuationQueue = DispatchQueue(label: "com.anchor.tokenContinuation")
    
    override init() {
        super.init()
        AppDelegate.shared = self
    }
    
    // MARK: - Authorization and Registration
    func requestAuthorizationAndRegister() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        
        guard granted else {
            throw NotificationError.notAuthorized
        }
        
        // Register for remote notifications on main thread
        await MainActor.run {
            #if !targetEnvironment(simulator)
            UIApplication.shared.registerForRemoteNotifications()
            #else
            // Simulator doesn't support APNs, so we'll fail the continuation
            tokenContinuationQueue.async { [weak self] in
                self?.tokenContinuation?.resume(throwing: NotificationError.registrationFailed)
                self?.tokenContinuation = nil
            }
            #endif
        }
    }
    
    // MARK: - Device Token Registration
    func registerForPushNotifications() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            tokenContinuationQueue.async { [weak self] in
                self?.tokenContinuation = continuation
            }
            
            Task {
                do {
                    try await self.requestAuthorizationAndRegister()
                } catch {
                    self.tokenContinuationQueue.async { [weak self] in
                        self?.tokenContinuation?.resume(throwing: error)
                        self?.tokenContinuation = nil
                    }
                }
            }
        }
    }
    
    // MARK: - UIApplicationDelegate Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize DeviceActivityMonitor to ensure it's discovered by iOS
        // This must be called on app launch for the monitor to be registered
        _ = AnchorDeviceActivityMonitor()
        
        // Initialize offline sync service for background syncing
        Task { @MainActor in
            // V1: offline unlock/proof sync removed
        }
        
        // Cleanup old cached data on app launch
        PersistenceService.shared.cleanupOldData()

        Task {
            await RemoteConfigService.shared.refresh()
        }

        logAppOpened(source: "launch")
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsServiceProvider.shared.flush()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AnalyticsServiceProvider.shared.flush()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token Data to hex string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Resume continuation with token
        tokenContinuationQueue.async { [weak self] in
            self?.tokenContinuation?.resume(returning: tokenString)
            self?.tokenContinuation = nil
        }
        
        // Send token to backend
        Task {
            do {
                try await NotificationService.shared.registerDeviceToken(deviceToken)
            } catch {
                print("Failed to register device token: \(error)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
        
        // Resume continuation with error
        tokenContinuationQueue.async { [weak self] in
            self?.tokenContinuation?.resume(throwing: NotificationError.registrationFailed)
            self?.tokenContinuation = nil
        }
    }
    
    // MARK: - URL Handling (Deep Links)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle Anchor deep links
        Task { @MainActor in
            _ = DeepLinkHandler.shared.handleURL(url)
        }

        logAppOpened(source: url.host)
        
        // Return true if it's an anchor:// URL, false otherwise
        return url.scheme == "anchor"
    }

    private func logAppOpened(source: String?) {
        let sharedState = AppGroupStorage.shared.getSessionState()
        let userState: AnalyticsUserState = (sharedState?.isActive ?? false) ? .anchored : .free
        var doubleValues: [String: Double] = [:]
        var stringValues: [String: String] = [:]
        if let source {
            stringValues["source"] = source
        }
        if let lastShieldHit = AppGroupStorage.shared.getLastShieldHitAt() {
            let delta = Date().timeIntervalSince(lastShieldHit)
            if delta >= 0 && delta <= 600 {
                doubleValues["timeFromShieldHitSeconds"] = delta
            }
        }
        let metrics = AnalyticsMetrics(doubleValues: doubleValues, stringValues: stringValues)
        let payload = AnalyticsPayload(userState: userState, metrics: metrics)
        AnalyticsServiceProvider.shared.log(event: .appOpened, payload: payload)
    }
}

@main
struct AnchorAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appCoordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            appCoordinator.rootView
                .task {
                    DailyAnchorService.shared.registerScheduleIfNeeded()
                    await DailyAnchorService.shared.applyIfNeeded()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        DailyAnchorService.shared.registerScheduleIfNeeded()
                        Task { await DailyAnchorService.shared.applyIfNeeded() }
                    }
                }
        }
    }
}
