import SwiftUI
import UserNotifications

struct PermissionsView: View {
    @ObservedObject var state: OnboardingState
    let onContinue: () -> Void

    @State private var screenTimeStatus: String = "Not requested"
    @State private var notificationStatus: String = "Not requested"
    @State private var errorMessage: String?

    private let screenTimeService = ScreenTimeService.shared

    var body: some View {
        VStack(spacing: AnchorTheme.Spacing.lg) {
            Spacer()

            VStack(spacing: AnchorTheme.Spacing.sm) {
                Text("Permissions")
                    .font(AnchorTheme.Typography.title)
                    .foregroundColor(AnchorTheme.textPrimary)

                Text("Anchor needs these to block apps and notify you when you’re done.")
                    .font(AnchorTheme.Typography.subtitle)
                    .foregroundColor(AnchorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AnchorTheme.Spacing.md) {
                OnboardingCard {
                    VStack(alignment: .leading, spacing: AnchorTheme.Spacing.sm) {
                        Text("Screen Time")
                            .font(AnchorTheme.Typography.body)
                            .foregroundColor(AnchorTheme.textPrimary)
                        Text(screenTimeStatus)
                            .font(AnchorTheme.Typography.caption)
                            .foregroundColor(AnchorTheme.textSecondary)
                        SecondaryButton(title: "Allow Screen Time") {
                            Task { await requestScreenTime() }
                        }
                    }
                }

                OnboardingCard {
                    VStack(alignment: .leading, spacing: AnchorTheme.Spacing.sm) {
                        Text("Notifications")
                            .font(AnchorTheme.Typography.body)
                            .foregroundColor(AnchorTheme.textPrimary)
                        Text(notificationStatus)
                            .font(AnchorTheme.Typography.caption)
                            .foregroundColor(AnchorTheme.textSecondary)
                        SecondaryButton(title: "Allow Notifications") {
                            Task { await requestNotifications() }
                        }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AnchorTheme.Typography.caption)
                    .foregroundColor(AppColors.error)
            }

            Spacer()

            PrimaryButton(title: "Continue", action: onContinue, disabled: !state.screenTimeGranted)
        }
        .onAppear {
            refreshStatuses()
        }
    }

    private func refreshStatuses() {
        let status = screenTimeService.getAuthorizationStatus()
        switch status {
        case .approved:
            screenTimeStatus = "Authorized"
            state.markScreenTimeGranted(true)
        case .denied:
            screenTimeStatus = "Denied"
            state.markScreenTimeGranted(false)
        case .restricted:
            screenTimeStatus = "Restricted"
            state.markScreenTimeGranted(false)
        case .notDetermined:
            screenTimeStatus = "Not requested"
            state.markScreenTimeGranted(false)
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    notificationStatus = "Authorized"
                    state.markNotificationsGranted(true)
                case .denied:
                    notificationStatus = "Denied"
                    state.markNotificationsGranted(false)
                case .notDetermined:
                    notificationStatus = "Not requested"
                    state.markNotificationsGranted(false)
                @unknown default:
                    notificationStatus = "Unknown"
                    state.markNotificationsGranted(false)
                }
            }
        }
    }

    private func requestScreenTime() async {
        do {
            try await screenTimeService.requestAuthorization()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        refreshStatuses()
    }

    private func requestNotifications() async {
        do {
            if let delegate = AppDelegate.shared {
                _ = try await delegate.registerForPushNotifications()
                errorMessage = nil
            } else {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                if !granted {
                    errorMessage = "Notifications were not granted."
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        refreshStatuses()
    }
}
