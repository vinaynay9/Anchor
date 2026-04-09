import SwiftUI
import Foundation
import Shared

@MainActor
class SettingsViewModel: ObservableObject {
    // Notification toggles with @AppStorage
    @AppStorage("sessionRemindersEnabled") var sessionRemindersEnabled: Bool = true

    // Alert state
    @Published var showClearDataAlert = false
    @Published var showEmergencyUnanchorSheet = false
    @Published var emergencyReason: String = ""
    @Published var emergencyDurationMinutes: Int = 30
    @Published var isProcessingEmergencyUnanchor = false
    @Published var dailyAnchorTime: Date
    @Published var showLockTimeConfirmation = false
    @Published var pendingLockTime: Date?
    @Published var inviteState: InviteState?
    @Published var showDeleteAccountAlert = false
    @Published var isDeletingAccount = false

    private let anchorScheduleService = AnchorScheduleService.shared
    private let dailyAnchorService = DailyAnchorService.shared
    private let notificationService: NotificationServiceProtocol
    private let screenTimeService: ScreenTimeServiceProtocol
    private let inviteService: InviteServiceProtocol
    private let storage = AppGroupStorage.shared

    // MARK: - Real user info from AppGroup

    var userInitials: String {
        let personal = storage.getPersonalInfo()
        let first = personal?.firstName.first.map(String.init) ?? ""
        let last = personal?.lastName.first.map(String.init) ?? ""
        let initials = (first + last).uppercased()
        if !initials.isEmpty { return initials }
        let display = storage.getProfile()?.displayName ?? ""
        return String(display.prefix(2)).uppercased().ifEmpty("?")
    }

    var displayName: String {
        let personal = storage.getPersonalInfo()
        if let first = personal?.firstName, !first.isEmpty {
            let last = personal?.lastName ?? ""
            return last.isEmpty ? first : "\(first) \(last)"
        }
        let profile = storage.getProfile()
        if let display = profile?.displayName, !display.isEmpty { return display }
        return "Anchor User"
    }

    var userEmail: String {
        storage.getProfileEmail() ?? "—"
    }

    init(
        notificationService: NotificationServiceProtocol = NotificationService.shared,
        screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared,
        inviteService: InviteServiceProtocol = InviteService.shared
    ) {
        self.notificationService = notificationService
        self.screenTimeService = screenTimeService
        self.inviteService = inviteService

        let schedule = anchorScheduleService.dailyAnchorTime
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = schedule.hour
        components.minute = schedule.minute
        dailyAnchorTime = Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Profile editing stubs

    func editProfile() {
        // TODO: navigate to profile edit view
        print("Edit Profile tapped")
    }

    func changeDisplayName() {
        // TODO: show name edit sheet
        print("Change Display Name tapped")
    }

    // MARK: - Data management

    func clearLocalData() {
        showClearDataAlert = true
    }

    func confirmClearLocalData() {
        showClearDataAlert = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ToastManager.shared.show("Data Cleared")
        }
    }

    func updateDailyAnchorTime(_ date: Date) {
        dailyAnchorTime = date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let time = DailyAnchorTime(hour: hour, minute: minute)
        anchorScheduleService.updateDailyAnchorTime(time)
        dailyAnchorService.updateLockStartTime(time)
    }

    func requiresConfirmation(for date: Date) -> Bool {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return hour > 0 || minute > 0
    }

    // MARK: - Emergency unanchor

    func requestEmergencyUnanchor() {
        guard !emergencyReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isProcessingEmergencyUnanchor = true

        Task {
            let durationSeconds = TimeInterval(emergencyDurationMinutes * 60)
            await screenTimeService.emergencyUnanchor(duration: durationSeconds)
            let payload = AnalyticsPayload(
                userState: .free,
                metrics: AnalyticsMetrics(doubleValues: ["durationMinutes": Double(emergencyDurationMinutes)])
            )
            AnalyticsServiceProvider.shared.log(event: .emergencyUnanchorUsed, payload: payload)

            await MainActor.run {
                isProcessingEmergencyUnanchor = false
                showEmergencyUnanchorSheet = false
                emergencyReason = ""
                HapticFeedback.success()
                ToastManager.shared.showWarning("Emergency unanchor active.")
            }
        }
    }

    // MARK: - Export / external

    func exportActivityLog() {
        print("Export Activity Log tapped")
    }

    func openPrivacyPolicy() {
        if let url = URL(string: "https://getanchor.app/privacy") {
            UIApplication.shared.open(url)
        }
    }

    func openTerms() {
        if let url = URL(string: "https://getanchor.app/terms") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Sign out

    func signOut() {
        Task {
            do {
                try await AuthService.shared.signOut()
                // Clear local app data on sign out
                AppGroupStorage.shared.setDailyGoalProgress(nil)
                // AppCoordinator will observe UserDefaults change and route to auth
            } catch {
                LoggerService.shared.logWarning("Sign out error: \(error.localizedDescription)", category: "Settings")
            }
        }
    }

    // MARK: - Delete account

    func confirmDeleteAccount() {
        isDeletingAccount = true
        Task {
            // Clear local data
            AppGroupStorage.shared.setDailyGoalProgress(nil)
            AppGroupStorage.shared.setShieldState(nil)
            UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.currentUserId)

            // TODO: [Supabase Migration] Call server-side delete
            // try await SupabaseClient.shared.auth.signOut()
            // try await SupabaseClient.shared.from("users").delete().eq("id", userId).execute()

            do {
                try await AuthService.shared.signOut()
            } catch { /* ignore */ }

            await MainActor.run {
                isDeletingAccount = false
                // AppCoordinator will reroute to auth
            }
        }
    }

    // MARK: - Invite

    func loadInviteState() async {
        let state = await inviteService.currentInviteState()
        await MainActor.run {
            self.inviteState = state
        }
    }

    func refreshInviteStatsIfNeeded(force: Bool = false) async {
        await inviteService.refreshInviteStatsIfNeeded(force: force)
        await loadInviteState()
    }

    func sharePayload() async -> (url: URL, message: String) {
        await inviteService.sharePayload()
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - String helper

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
