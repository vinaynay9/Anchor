import SwiftUI
import Foundation
import Shared

@MainActor
class SettingsViewModel: ObservableObject {
    // Notification toggles with @AppStorage
    @AppStorage("sessionRemindersEnabled") var sessionRemindersEnabled: Bool = true
    @AppStorage("unlockRequestAlertsEnabled") var unlockRequestAlertsEnabled: Bool = true
    @AppStorage("witnessRequestEnabled") var witnessRequestEnabled: Bool = true
    
    // Alert state
    @Published var showClearDataAlert = false
    @Published var showEmergencyUnanchorSheet = false
    @Published var emergencyReason: String = ""
    @Published var emergencyDurationMinutes: Int = 30
    @Published var isProcessingEmergencyUnanchor = false
    @Published var dailyAnchorTime: Date
    @Published var isCognitoSignedIn: Bool = false
    
    private let anchorScheduleService = AnchorScheduleService.shared
    private let friendService: FriendServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let auditService: AuditServiceProtocol
    private let screenTimeService: ScreenTimeServiceProtocol
    
    // User info (mock for now - should come from AuthService)
    var userInitials: String {
        // TODO: Get from actual user data
        return "U"
    }
    
    var displayName: String {
        // TODO: Get from actual user data
        return "User"
    }
    
    var userEmail: String {
        // TODO: Get from actual user data
        return "user@example.com"
    }
    
    init(
        friendService: FriendServiceProtocol = FriendService.shared,
        notificationService: NotificationServiceProtocol = NotificationService.shared,
        auditService: AuditServiceProtocol = AuditService.shared,
        screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared
    ) {
        self.friendService = friendService
        self.notificationService = notificationService
        self.auditService = auditService
        self.screenTimeService = screenTimeService
        
        let schedule = anchorScheduleService.dailyAnchorTime
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = schedule.hour
        components.minute = schedule.minute
        dailyAnchorTime = Calendar.current.date(from: components) ?? Date()
        isCognitoSignedIn = CognitoAuthService.shared.isSignedIn
    }
    
    // Simulated actions
    func editProfile() {
        // Simulated action - no backend
        print("Edit Profile tapped")
    }
    
    func changeDisplayName() {
        // Simulated action - no backend
        print("Change Display Name tapped")
    }
    
    func clearLocalData() {
        showClearDataAlert = true
    }
    
    func confirmClearLocalData() {
        // Simulated action - no backend
        print("Clearing local data...")
        showClearDataAlert = false
        
        // Show success toast after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ToastManager.shared.show("Data Cleared")
        }
    }

    func updateDailyAnchorTime(_ date: Date) {
        dailyAnchorTime = date
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        anchorScheduleService.updateDailyAnchorTime(DailyAnchorTime(hour: hour, minute: minute))
    }

    func requestEmergencyUnanchor() {
        guard !emergencyReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isProcessingEmergencyUnanchor = true
        
        Task {
            let durationSeconds = TimeInterval(emergencyDurationMinutes * 60)
            let anchors = (try? await friendService.getFriends()) ?? []
            await screenTimeService.emergencyUnanchor(duration: durationSeconds)
            await notificationService.notifyAnchorsEmergencyUnanchor(
                anchors: anchors,
                reason: emergencyReason,
                duration: durationSeconds
            )
            
            let anchorIds = anchors.map(\.id)
            let event = AuditEvent(
                type: .emergencyUnanchor,
                reason: emergencyReason,
                durationMinutes: emergencyDurationMinutes,
                notifiedAnchorIds: anchorIds
            )
            auditService.recordEvent(event)

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
    
    func exportActivityLog() {
        // Simulated action - no backend
        print("Export Activity Log tapped")
    }
    
    func openPrivacyPolicy() {
        // Simulated action - no backend
        print("Privacy Policy tapped")
    }
    
    func openTerms() {
        // Simulated action - no backend
        print("Terms tapped")
    }
    
    func signOut() {
        // TODO: Integrate with AuthService
        Task {
            do {
                try await AuthService.shared.signOut()
                // Navigation will be handled by AppCoordinator
            } catch {
                print("Sign out error: \(error)")
            }
        }
    }
    
    func deleteAccount() {
        // TODO: Implement account deletion
        print("Delete Account tapped")
    }

    func refreshCognitoStatus() {
        isCognitoSignedIn = CognitoAuthService.shared.isSignedIn
    }

    func signInForRemoteConfig() {
        Task {
            do {
                try await CognitoAuthService.shared.signIn()
                await RemoteConfigService.shared.refresh()
                await MainActor.run {
                    self.isCognitoSignedIn = true
                }
            } catch {
                await MainActor.run {
                    self.isCognitoSignedIn = false
                }
                print("Cognito sign-in failed: \(error)")
            }
        }
    }

    func signOutCognito() {
        CognitoAuthService.shared.signOutLocal()
        isCognitoSignedIn = false
    }
    
    // Get app version
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
}
