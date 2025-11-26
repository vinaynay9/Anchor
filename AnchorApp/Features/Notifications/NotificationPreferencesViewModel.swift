import SwiftUI
import Combine

@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    // MARK: - Unlock Requests
    @AppStorage("notifyUnlockRequests") var notifyUnlockRequests: Bool = true
    @AppStorage("notifyRequestStatus") var notifyRequestStatus: Bool = true
    
    // MARK: - Session Reminders
    @AppStorage("notify5MinReminder") var notify5MinReminder: Bool = true
    @AppStorage("notifyEndOfSession") var notifyEndOfSession: Bool = true
    
    // MARK: - Daily Reports
    @AppStorage("notifyDailySummary") var notifyDailySummary: Bool = true
    @AppStorage("notifyWeeklyInsights") var notifyWeeklyInsights: Bool = false
    
    private let toastManager = ToastManager.shared
    
    func savePreferences() {
        // Show success toast
        toastManager.showSuccess("Preferences saved successfully")
    }
}

