import SwiftUI
import Shared

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var goalsViewModel = GoalViewModel()
    @EnvironmentObject var coordinator: MainTabFlow
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage(InternalToolsKeys.isEnabled) private var internalToolsEnabled: Bool = false
    @AppStorage("analyticsRemoteExportEnabled") private var analyticsRemoteExportEnabled: Bool = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    // Profile Section
                    profileSection
                    
                    // Permissions Section
                    permissionsSection
                    
                    // Friends & Accountability Section
                    friendsAccountabilitySection
                    
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
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("PROFILE")
                .font(AppTypography.captionBold)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            VStack(spacing: Theme.spacing2) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.anchorPrimary, AppColors.anchorAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text(viewModel.userInitials)
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.onPrimary)
                }
                .padding(.top, Theme.spacing)
                
                // Name
                Text(viewModel.displayName)
                    .font(AppTypography.title3)
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
    
    // MARK: - Permissions Section
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("PERMISSIONS")
                .font(AppTypography.captionBold)
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
    
    // MARK: - Friends & Accountability Section
    private var friendsAccountabilitySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("FRIENDS & ACCOUNTABILITY")
                .font(AppTypography.captionBold)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            VStack(spacing: 0) {
                SettingsRowView(
                    icon: "person.2",
                    title: "Manage Friends",
                    action: {
                        // Navigate to friends tab
                        coordinator.friendsPath = NavigationPath()
                    }
                )
                
                Divider()
                    .background(AppColors.textSecondary.opacity(0.2))
                    .padding(.leading, 50)
                
                SettingsRowView(
                    icon: "checkmark.shield",
                    title: "Witness Request Toggle",
                    isOn: $viewModel.witnessRequestEnabled
                )
            }
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
    }
    
    // MARK: - App Controls Section
    private var appControlsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("APP CONTROLS")
                .font(AppTypography.captionBold)
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
                .font(AppTypography.captionBold)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            VStack(spacing: 0) {
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
    }
}
