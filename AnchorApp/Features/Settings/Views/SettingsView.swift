import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        ZStack {
            // Ultra-dark matte background
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Account Section
                    settingsSection(title: "Account") {
                        SettingsRowView(
                            icon: "person.circle",
                            title: "Edit Profile",
                            action: {
                                viewModel.editProfile()
                            }
                        )
                        
                        SettingsRowView(
                            icon: "textformat",
                            title: "Change Display Name",
                            action: {
                                viewModel.changeDisplayName()
                            }
                        )
                    }
                    
                    // Notifications Section
                    settingsSection(title: "Notifications") {
                        SettingsRowView(
                            icon: "bell",
                            title: "Session Reminders",
                            isOn: $viewModel.sessionRemindersEnabled
                        )
                        
                        SettingsRowView(
                            icon: "lock.open",
                            title: "Unlock Request Alerts",
                            isOn: $viewModel.unlockRequestAlertsEnabled
                        )
                    }
                    
                    // Privacy Section
                    settingsSection(title: "Privacy") {
                        SettingsRowView(
                            icon: "trash",
                            title: "Clear Local Data",
                            action: {
                                viewModel.clearLocalData()
                            }
                        )
                        
                        SettingsRowView(
                            icon: "square.and.arrow.up",
                            title: "Export Activity Log",
                            action: {
                                viewModel.exportActivityLog()
                            }
                        )
                    }
                    
                    // About Section
                    settingsSection(title: "About") {
                        SettingsRowView(
                            icon: "info.circle",
                            title: "Version",
                            trailing: Text(viewModel.appVersion)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        )
                        
                        SettingsRowView(
                            icon: "hand.raised",
                            title: "Privacy Policy",
                            action: {
                                viewModel.openPrivacyPolicy()
                            }
                        )
                        
                        SettingsRowView(
                            icon: "doc.text",
                            title: "Terms",
                            action: {
                                viewModel.openTerms()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
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
    
    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                content()
            }
        }
    }
}
