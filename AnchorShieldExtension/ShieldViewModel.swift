import SwiftUI
import Foundation
import UIKit
import Combine
import Shared

@MainActor
class ShieldViewModel: ObservableObject {
    @Published var title: String = "Stay Focused"
    @Published var subtitle: String = "This app is blocked during your focus session."
    @Published var remainingTimeText: String?
    @Published var isWaitingForFriendApproval: Bool = false
    @Published var primaryButtonTitle: String = "Open Anchor"
    
    private let appGroupStorage = AppGroupStorage.shared
    private var cancellables = Set<AnyCancellable>()
    
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
    }
    
    func refresh() {
        let state = appGroupStorage.getSessionState() // Now returns SharedSessionState?
        let hasPendingUnlock = appGroupStorage.hasPendingUnlockRequest()
        
        // Check for pending unlock request first
        if hasPendingUnlock {
            isWaitingForFriendApproval = true
            title = "Unlock Request Pending"
            subtitle = "Waiting for your accountability partner to review your unlock request."
            remainingTimeText = nil
        } else if let state = state, state.isActive {
            // Active session
            isWaitingForFriendApproval = false
            title = "Stay Focused"
            subtitle = "This app is blocked during your focus session."
            
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
            title = "App Blocked"
            subtitle = "You're currently blocked by Anchor."
            remainingTimeText = nil
        }
    }
    
    func openAnchorApp() {
        guard let url = URL(string: ShieldURLScheme.anchorApp) else { return }
        
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

