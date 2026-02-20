import SwiftUI
import Foundation
import Combine
import Shared
import os.log

// Lightweight logging for ShieldExtension
private let shieldLog = OSLog(subsystem: "com.vinay.Anchor", category: "Shield")

@MainActor
class ShieldViewModel: ObservableObject {
    @Published var title: String = "Anchored"
    @Published var subtitle: String = "Complete your goals in Anchor to unlock apps."
    @Published var remainingTimeText: String?
    @Published var primaryButtonTitle: String = "Open Anchor"
    
    // Goal progress state (calculated in ViewModel, not View)
    @Published var goalProgressText: String?
    @Published var goalCompletedCount: Int = 0
    @Published var goalTotalCount: Int = 0
    
    private let appGroupStorage = AppGroupStorage.shared
    private var openURLHandler: ((URL) -> Void)?
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
        refreshGoalProgress()
    }

    var blockedAppToken: String? {
        appGroupStorage.getCurrentBlockedBundleId()
    }
    
    // MARK: - Goal Progress (Business Logic)
    
    /// Updates goal progress state. Called from ViewModel to keep business logic out of View.
    func refreshGoalProgress() {
        let state = appGroupStorage.getOnboardingState()
        let total = state?.goals.count ?? 0
        let progress = appGroupStorage.getDailyGoalProgress()
        let today = localDayString(for: Date())

        goalTotalCount = total
        if let progress, progress.date == today {
            goalCompletedCount = progress.completedGoalIds.count
        } else {
            goalCompletedCount = 0
        }
        if total > 0 {
            goalProgressText = "\(goalCompletedCount) / \(total) complete"
        } else {
            goalProgressText = nil
        }
    }
    
    func refresh() {
        let shieldState = appGroupStorage.getShieldState()
        title = (shieldState?.isBlocking ?? false) ? "Anchored" : "Locked"
        subtitle = "Complete your goals in Anchor to unlock apps."
        primaryButtonTitle = "Open Anchor"
        remainingTimeText = nil
    }
    
    func openAnchorApp() {
        os_log("Opening Anchor app from shield", log: shieldLog, type: .info)
        
        let bundleId = appGroupStorage.getCurrentBlockedBundleId()
        
        // Write context to AppGroupStorage before opening app
        // This allows the app to know it was opened from the shield
        if let bundleId = bundleId {
            appGroupStorage.setPendingDeepLinkContext(bundleId: bundleId)
        }
        
        openURL(ShieldURLScheme.anchorApp)
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // Use extension-safe URL opening via injected handler
        openURLHandler?(url)
    }

    func setOpenURLHandler(_ handler: @escaping (URL) -> Void) {
        openURLHandler = handler
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

    private func localDayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
