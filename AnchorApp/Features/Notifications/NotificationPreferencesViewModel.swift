import SwiftUI
import Combine

@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    // MARK: - Session Reminders
    @AppStorage("notify5MinReminder") var notify5MinReminder: Bool = true
    @AppStorage("notifyEndOfSession") var notifyEndOfSession: Bool = true
    
    // MARK: - Daily Reports
    @AppStorage("notifyDailySummary") var notifyDailySummary: Bool = true
    @AppStorage("notifyWeeklySummary") var notifyWeeklySummary: Bool = false
    
    func savePreferences() {
        // Show success toast
        ToastManager.shared.show("Preferences saved successfully")
    }
}
