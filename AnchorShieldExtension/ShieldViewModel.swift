import SwiftUI
import Foundation
import UIKit
import Combine
import ManagedSettingsUI
import Shared
import os.log

// Lightweight logging for ShieldExtension
private let shieldLog = OSLog(subsystem: "com.vinay.Anchor", category: "Shield")

@MainActor
class ShieldViewModel: ObservableObject {
    @Published var title: String = "You're anchored."
    @Published var subtitle: String = "This app is blocked during your anchor window."
    @Published var remainingTimeText: String?
    @Published var isWaitingForFriendApproval: Bool = false
    @Published var primaryButtonTitle: String = "Request Unlock"
    @Published var secondaryButtonTitle: String = "Message Your Accountability Partner"
    @Published var explanationText: String = "Why is this blocked?"
    
    // Goal progress state (calculated in ViewModel, not View)
    @Published var goalProgressText: String?
    @Published var goalCompletedCount: Int = 0
    @Published var goalTotalCount: Int = 0
    
    private let appGroupStorage = AppGroupStorage.shared
    private let goalService = GoalService.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// ShieldDecision helper for bundle ID matching and unlock logic
    private var shieldDecision: ShieldDecision?
    
    init() {
        // Subscribe to AppGroupStorage updates for real-time sync
        appGroupStorage.updatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
        
        // Initial refresh
        refresh()
        refreshGoalProgress()
    }

    var blockedAppToken: String? {
        shieldDecision?.blockedBundleId ?? appGroupStorage.getCurrentBlockedBundleId()
    }
    
    // MARK: - Goal Progress (Business Logic)
    
    /// Updates goal progress state. Called from ViewModel to keep business logic out of View.
    func refreshGoalProgress() {
        let goals = goalService.loadGoals()
        goalTotalCount = goals.count
        goalCompletedCount = goals.filter { $0.isCompleted }.count
        
        if goalTotalCount > 0 {
            goalProgressText = "\(goalCompletedCount)/\(goalTotalCount) goals completed"
        } else {
            goalProgressText = nil
        }
    }
    
    /// Sets the shield context to enable bundle ID extraction and matching
    /// - Parameter context: The shield configuration context
    func setContext(_ context: ShieldConfigurationContext) {
        shieldDecision = ShieldDecision(context: context)
        refresh()
    }
    
    func refresh() {
        let state = appGroupStorage.getSessionState() // Now returns SharedSessionState?
        let hasPendingUnlock = appGroupStorage.hasPendingUnlockRequest()
        
        // Use ShieldDecision to check if unlock is approved for this specific app
        let isUnlockApproved = shieldDecision?.isUnlockApproved() ?? false
        
        // Check if unlock has been approved for this app - show approved state
        if isUnlockApproved {
            isWaitingForFriendApproval = false
            title = "Unlock approved."
            subtitle = "Your anchor approved this unlock. You can access the app now."
            primaryButtonTitle = "Open Anchor"
            secondaryButtonTitle = "Return to Anchor"
            explanationText = "Your unlock request has been approved. The app should be accessible now. If you still see this screen, try closing and reopening the app."
            remainingTimeText = nil
            return
        }
        
        // Check for pending unlock request
        if hasPendingUnlock {
            isWaitingForFriendApproval = true
            title = "Unlock pending."
            subtitle = "Waiting for your anchor to review your request."
            primaryButtonTitle = "Open Anchor"
            secondaryButtonTitle = "Message Your Accountability Partner"
            explanationText = "Your unlock request is being reviewed. You'll be notified once your partner responds."
            remainingTimeText = nil
        } else if let state = state, state.isActive {
            // Active session
            isWaitingForFriendApproval = false
            title = "You're anchored."
            subtitle = "This app is blocked during your anchor window."
            primaryButtonTitle = "Request Unlock"
            secondaryButtonTitle = "Message Your Accountability Partner"
            explanationText = "This app is blocked to help you stay focused. You can request temporary access or message your accountability partner."
            
            // Calculate remaining time from remainingSeconds or endTime
            if let seconds = state.remainingSeconds {
                remainingTimeText = formatTime(TimeInterval(seconds))
            } else if let endTime = state.endTime {
                let remaining = max(0, endTime.timeIntervalSince(Date()))
                remainingTimeText = formatTime(remaining)
            } else {
                remainingTimeText = nil
            }
        } else {
            // No active session - fallback state
            isWaitingForFriendApproval = false
            title = "You're anchored."
            subtitle = "This app is blocked by Anchor."
            primaryButtonTitle = "Open Anchor"
            secondaryButtonTitle = "Message Your Accountability Partner"
            explanationText = "This app is blocked. Open Anchor to manage your session."
            remainingTimeText = nil
        }
    }
    
    func openAnchorApp() {
        os_log("Opening Anchor app from shield", log: shieldLog, type: .info)
        
        // Get bundle ID from ShieldDecision if available
        let bundleId = shieldDecision?.blockedBundleId ?? appGroupStorage.getCurrentBlockedBundleId()
        
        // Write context to AppGroupStorage before opening app
        // This allows the app to know it was opened from the shield
        if let bundleId = bundleId {
            appGroupStorage.setPendingDeepLinkContext(bundleId: bundleId)
        }
        
        openURL(ShieldURLScheme.anchorApp)
    }
    
    func openUnlockRequest() {
        os_log("Opening unlock request from shield", log: shieldLog, type: .info)
        
        // Get bundle ID from ShieldDecision if available, fall back to storage
        let bundleId = shieldDecision?.blockedBundleId ?? appGroupStorage.getCurrentBlockedBundleId()
        
        // Log for debugging
        os_log("Unlock request bundle ID: %{public}@", log: shieldLog, type: .info, bundleId ?? "nil")
        
        // Write unlock request context with bundle ID for the main app
        // The main app will use this to pass bundleId to the unlock request
        appGroupStorage.setPendingDeepLinkContext(
            requestId: nil,  // Will be assigned when request is created
            bundleId: bundleId
        )
        
        // Also store the bundle ID directly for easy access
        if let bundleId = bundleId {
            appGroupStorage.setCurrentBlockedBundleId(bundleId)
        }
        
        openURL(ShieldURLScheme.unlockRequest)
    }
    
    func openMessagePartner() {
        openURL(ShieldURLScheme.messagePartner)
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // In a shield extension, open the main app via URL scheme
        // Note: UIApplication.shared is available in App Extensions including shield extensions
        DispatchQueue.main.async {
            let sharedApp = UIApplication.shared
            if sharedApp.canOpenURL(url) {
                sharedApp.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
