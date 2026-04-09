import SwiftUI
import Shared
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var coordinator: MainTabFlow
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage(InternalToolsKeys.isEnabled) private var internalToolsEnabled: Bool = false
    @AppStorage("analyticsRemoteExportEnabled") private var analyticsRemoteExportEnabled: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var lockTime: Date = Date()
    @State private var previousLockTime: Date = Date()
    @State private var lockConfirmationText: String = ""
    @State private var lockConfirmationError: String?

    private let lockConfirmationPhrase = "I know I am destroying my habits by changing my lock time"

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    profileSection
                    preferencesSection
                    socialSection
                    accountSection
                    debugSection
                }
                .padding(.horizontal, Theme.spacing2)
                .padding(.vertical, Theme.spacing3)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("Clear Local Data", isPresented: $viewModel.showClearDataAlert) {
            Button("Cancel", role: .cancel) { viewModel.showClearDataAlert = false }
            Button("Clear", role: .destructive) { viewModel.confirmClearLocalData() }
        } message: {
            Text("This will permanently delete all local data. This action cannot be undone.")
        }
        .alert("Delete Account", isPresented: $viewModel.showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { viewModel.showDeleteAccountAlert = false }
            Button("Delete Forever", role: .destructive) { viewModel.confirmDeleteAccount() }
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showLockTimeConfirmation) {
            lockTimeConfirmationSheet
        }
        .onAppear {
            lockTime = viewModel.dailyAnchorTime
            previousLockTime = lockTime
            Task {
                await viewModel.loadInviteState()
                await viewModel.refreshInviteStatsIfNeeded()
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            sectionLabel("PROFILE")

            VStack(spacing: Theme.spacing2) {
                // Avatar circle
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(viewModel.userInitials)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.onPrimary)
                        )

                    // Camera badge (placeholder for future photo upload)
                    Circle()
                        .fill(AppColors.surface)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                        )
                        .overlay(Circle().stroke(AppColors.background, lineWidth: 2))
                }
                .padding(.top, Theme.spacing)

                Text(viewModel.displayName)
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)

                Text(viewModel.userEmail)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.spacing2)
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            guard InternalTools.canToggle(user: authViewModel.currentUser) else { return }
            internalToolsEnabled.toggle()
            ToastManager.shared.show(internalToolsEnabled ? "Internal tools enabled" : "Internal tools disabled")
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            sectionLabel("PREFERENCES")

            VStack(spacing: 0) {
                NavigationLink(destination: EditGoalsView()) {
                    SettingsRowView(icon: "target", title: "Edit Goals", showChevron: true)
                }

                divider

                NavigationLink(destination: LockScheduleView(viewModel: LockScheduleViewModel(), onNext: {})) {
                    SettingsRowView(icon: "moon.stars.fill", title: "Edit Lock Schedule", showChevron: true)
                }

                divider

                NavigationLink(destination: EditBlockedAppsView()) {
                    SettingsRowView(icon: "app.badge.checkmark.fill", title: "Edit Blocked Apps", showChevron: true)
                }

                divider

                NavigationLink(destination: UnlockPolicyView(viewModel: UnlockPolicyViewModel(), onNext: { _ in })) {
                    SettingsRowView(icon: "gift.fill", title: "Edit Reward Rules", showChevron: true)
                }
            }
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
    }

    // MARK: - Social Section

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            sectionLabel("SOCIAL")

            VStack(alignment: .leading, spacing: Theme.spacing2) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invite Friends")
                            .font(AppTypography.sectionHeader)
                            .foregroundColor(AppColors.textPrimary)

                        Text("Each friend earns you 1 month free when Anchor goes paid.")
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(2)

                        let count = viewModel.inviteState?.inviteCount ?? 0
                        Text(count == 0 ? "No friends invited yet" : "\(count) friend\(count == 1 ? "" : "s") invited")
                            .font(AppTypography.caption)
                            .foregroundColor(count > 0 ? AppColors.accent : AppColors.textSecondary.opacity(0.60))
                            .padding(.top, 2)
                    }
                    Spacer()
                }

                HStack(spacing: Theme.spacing) {
                    Button(action: { shareInvite() }) {
                        Text("Share Link")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryPressableButtonStyle())

                    Button(action: { copyInviteLink() }) {
                        Text("Copy Link")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryPressableButtonStyle())
                }
            }
            .padding(Theme.spacing2)
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.accent.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            sectionLabel("ACCOUNT")

            VStack(spacing: 0) {
                SettingsRowView(
                    icon: "lock.shield.fill",
                    title: "Screen Time",
                    subtitle: screenTimePermissionStatus,
                    showChevron: true,
                    action: nil
                )
                .overlay(
                    NavigationLink(destination: ScreenTimePermissionView()) {
                        Color.clear
                    }
                )

                divider

                SettingsRowView(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    showChevron: true,
                    action: { viewModel.openPrivacyPolicy() }
                )

                divider

                SettingsRowView(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    showChevron: true,
                    action: { viewModel.openTerms() }
                )

                divider

                SettingsRowView(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    action: { viewModel.signOut() }
                )

                divider

                SettingsRowView(
                    icon: "trash",
                    title: "Delete Account",
                    titleColor: AppColors.error,
                    action: { viewModel.showDeleteAccountAlert = true }
                )
            }
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
    }

    // MARK: - Debug section (App Controls)

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            sectionLabel("APP CONTROLS")

            VStack(spacing: 0) {
                NavigationLink(destination: DebugDiagnosticsView()) {
                    SettingsRowView(
                        icon: "stethoscope",
                        title: "Debug Diagnostics",
                        subtitle: "View logs and diagnostics",
                        showChevron: true
                    )
                }

                divider

                SettingsRowView(
                    icon: "arrow.clockwise",
                    title: "Reset Daily Habits",
                    action: { AppGroupStorage.shared.setDailyGoalProgress(nil) }
                )

                divider

                SettingsRowView(
                    icon: "trash",
                    title: "Clear Session Data",
                    action: { viewModel.clearLocalData() }
                )

                #if DEBUG
                divider
                SettingsRowView(
                    icon: "arrow.uturn.backward",
                    title: "Reset Onboarding (Debug)",
                    action: {
                        hasCompletedOnboarding = false
                        hasSeenOnboarding = false
                    }
                )
                #endif

                #if INTERNAL_TOOLS || DEBUG
                if InternalTools.canAccessAdmin(user: authViewModel.currentUser) {
                    divider
                    NavigationLink(destination: AdminRootView()) {
                        SettingsRowView(
                            icon: "shield.lefthalf.filled",
                            title: "Admin Tools",
                            subtitle: "Internal dashboards",
                            showChevron: true
                        )
                    }
                    divider
                    SettingsRowView(
                        icon: "square.and.arrow.up",
                        title: "Enable Remote Export (stub)",
                        isOn: $analyticsRemoteExportEnabled
                    )
                }
                #endif
            }
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)

            // App version
            Text("Anchor v\(viewModel.appVersion)")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary.opacity(0.50))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
    }

    // MARK: - Lock time confirmation sheet

    private var lockTimeConfirmationSheet: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: Theme.spacing3) {
                Text("Confirm change")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.textPrimary)

                Text("Type the phrase below to move your lock time later.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text(lockConfirmationPhrase)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                TextField("Type the phrase", text: $lockConfirmationText)
                    .textFieldStyle(AppTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if let error = lockConfirmationError {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.accent)
                }

                HStack(spacing: Theme.spacing) {
                    Button("Cancel") {
                        lockConfirmationText = ""
                        lockConfirmationError = nil
                        viewModel.showLockTimeConfirmation = false
                    }
                    .buttonStyle(SecondaryPressableButtonStyle())

                    Button("Confirm") {
                        let input = lockConfirmationText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        guard input == lockConfirmationPhrase.lowercased(), let pending = viewModel.pendingLockTime else {
                            lockConfirmationError = "Phrase does not match. Try again."
                            return
                        }
                        previousLockTime = pending
                        lockTime = pending
                        viewModel.updateDailyAnchorTime(pending)
                        lockConfirmationText = ""
                        lockConfirmationError = nil
                        viewModel.pendingLockTime = nil
                        viewModel.showLockTimeConfirmation = false
                    }
                    .buttonStyle(PrimaryPressableButtonStyle())
                }
            }
            .padding(Theme.spacing3)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textSecondary)
            .tracking(0.5)
    }

    private var divider: some View {
        Divider()
            .background(AppColors.textSecondary.opacity(0.2))
            .padding(.leading, 50)
    }

    private var screenTimePermissionStatus: String {
        switch ScreenTimeService.shared.getAuthorizationStatus() {
        case .approved: return "Authorized"
        case .denied:   return "Not Authorized"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Set"
        }
    }

    private func shareInvite() {
        Task {
            let payload = await viewModel.sharePayload()
            await MainActor.run {
                shareItems = [payload.message, payload.url]
                showShareSheet = true
            }
        }
    }

    private func copyInviteLink() {
        Task {
            let payload = await viewModel.sharePayload()
            await MainActor.run {
                UIPasteboard.general.string = payload.url.absoluteString
                ToastManager.shared.show("Invite link copied")
            }
        }
    }
}

// MARK: - Edit Goals placeholder (navigates to goal list in edit mode)

private struct EditGoalsView: View {
    var body: some View {
        GoalsListView()
            .navigationTitle("Edit Goals")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Edit Blocked Apps

private struct EditBlockedAppsView: View {
    @State private var viewModel = OnboardingAppSelectionViewModel()
    @State private var showPicker = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: Theme.spacing3) {
                Text("Tap below to update which apps are blocked during Anchored mode.")
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)

                Button {
                    showPicker = true
                } label: {
                    Text("Open App Picker")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryPressableButtonStyle())
                .padding(.horizontal, Theme.spacing3)
            }
            .padding(.top, Theme.spacing4)
        }
        .navigationTitle("Blocked Apps")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPicker) {
            FamilyActivityPickerWrapper(selection: $viewModel.blockedSelection) {
                Task { await viewModel.persistSelections() }
            }
        }
        .task { await viewModel.loadState() }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
