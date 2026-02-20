import SwiftUI
import Shared
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var goalsViewModel = GoalViewModel()
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
                    // Invite CTA
                    inviteCTASection

                    // Profile Section
                    profileSection

                    // Lock Schedule
                    lockScheduleSection
                    
                    // Permissions Section
                    permissionsSection
                    
                    // App Controls Section
                    appControlsSection
                    
                    // Account Section
                    accountSection
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
            Button("Cancel", role: .cancel) {
                viewModel.showClearDataAlert = false
            }
            Button("Clear", role: .destructive) {
                viewModel.confirmClearLocalData()
            }
        } message: {
            Text("This will permanently delete all local data. This action cannot be undone.")
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

    // MARK: - Invite CTA
    private var inviteCTASection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("INVITE FRIENDS")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: Theme.spacing2) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Invite Friends")
                            .font(AppTypography.sectionHeader)
                            .foregroundColor(AppColors.textPrimary)

                        Text(inviteSubtitle)
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.textSecondary)
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
            .background(AppColors.surface)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
            )
            .anchorHover()
        }
    }

    private var inviteSubtitle: String {
        let count = viewModel.inviteState?.inviteCount ?? 0
        return "Your link • \(count) invited"
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
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("PROFILE")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            VStack(spacing: Theme.spacing2) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text(viewModel.userInitials)
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.onPrimary)
                }
                .padding(.top, Theme.spacing)
                
                // Name
                Text(viewModel.displayName)
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
                
                // Email
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
            ToastManager.shared.show(
                internalToolsEnabled ? "Internal tools enabled" : "Internal tools disabled"
            )
        }
    }

    // MARK: - Lock Schedule
    private var lockScheduleSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("LOCK SCHEDULE")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: Theme.spacing2) {
                Text("Lock start time")
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)

                DatePicker(
                    "",
                    selection: $lockTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .onChange(of: lockTime) { newValue in
                    if viewModel.requiresConfirmation(for: newValue) {
                        viewModel.pendingLockTime = newValue
                        viewModel.showLockTimeConfirmation = true
                        lockTime = previousLockTime
                    } else {
                        previousLockTime = newValue
                        viewModel.updateDailyAnchorTime(newValue)
                    }
                }

                Text("Default is 12:00 AM. Later times require confirmation.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(Theme.spacing2)
            .background(AppColors.surface)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
            )
        }
    }

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
                        let expected = lockConfirmationPhrase.lowercased()
                        guard input == expected, let pending = viewModel.pendingLockTime else {
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
    
    // MARK: - Permissions Section
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("PERMISSIONS")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            VStack(spacing: 0) {
                NavigationLink(destination: ScreenTimePermissionView()) {
                    SettingsRowView(
                        icon: "lock.shield.fill",
                        title: "Screen Time Permissions",
                        subtitle: screenTimePermissionStatus,
                        showChevron: true
                    )
                }
            }
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
    }
    
    private var screenTimePermissionStatus: String {
        let status = ScreenTimeService.shared.getAuthorizationStatus()
        switch status {
        case .approved:
            return "Authorized"
        case .denied:
            return "Not Authorized"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Set"
        }
    }
    
    // MARK: - App Controls Section
    private var appControlsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("APP CONTROLS")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            VStack(spacing: 0) {
                SettingsRowView(
                    icon: "arrow.clockwise",
                    title: "Reset Daily Habits",
                    action: {
                        goalsViewModel.resetGoalsDaily()
                    }
                )
                
                Divider()
                    .background(AppColors.textSecondary.opacity(0.2))
                    .padding(.leading, 50)
                
                SettingsRowView(
                    icon: "trash",
                    title: "Clear Session Data",
                    action: {
                        viewModel.clearLocalData()
                    }
                )
                
                Divider()
                    .background(AppColors.textSecondary.opacity(0.2))
                    .padding(.leading, 50)
                
                NavigationLink(destination: DebugDiagnosticsView()) {
                    SettingsRowView(
                        icon: "stethoscope",
                        title: "Debug Diagnostics",
                        subtitle: "View logs and diagnostics",
                        showChevron: true
                    )
                }

                #if DEBUG
                Divider()
                    .background(AppColors.textSecondary.opacity(0.2))
                    .padding(.leading, 50)

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
                    Divider()
                        .background(AppColors.textSecondary.opacity(0.2))
                        .padding(.leading, 50)
                    
                    NavigationLink(destination: AdminRootView()) {
                        SettingsRowView(
                            icon: "shield.lefthalf.filled",
                            title: "Admin Tools",
                            subtitle: "Internal dashboards",
                            showChevron: true
                        )
                    }
                    
                    Divider()
                        .background(AppColors.textSecondary.opacity(0.2))
                        .padding(.leading, 50)
                    
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
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("ACCOUNT")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            VStack(spacing: 0) {
                SettingsRowView(
                    icon: "cloud",
                    title: viewModel.isCognitoSignedIn ? "Remote Config Connected" : "Connect Remote Config",
                    subtitle: viewModel.isCognitoSignedIn ? "Signed in to Cognito" : "Sign in to fetch remote config",
                    action: {
                        if viewModel.isCognitoSignedIn {
                            viewModel.signOutCognito()
                        } else {
                            viewModel.signInForRemoteConfig()
                        }
                    }
                )
                
                Divider()
                    .background(AppColors.textSecondary.opacity(0.2))
                    .padding(.leading, 50)
                
                SettingsRowView(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    action: {
                        viewModel.signOut()
                    }
                )
                
                Divider()
                    .background(AppColors.textSecondary.opacity(0.2))
                    .padding(.leading, 50)
                
                SettingsRowView(
                    icon: "trash",
                    title: "Delete Account",
                    titleColor: AppColors.error,
                    action: {
                        viewModel.deleteAccount()
                    }
                )
            }
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
        .onAppear {
            viewModel.refreshCognitoStatus()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
