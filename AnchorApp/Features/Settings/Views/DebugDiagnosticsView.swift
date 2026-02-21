import SwiftUI
import Combine
import Shared

/// Debug diagnostics view for viewing logs and toggling verbose logging.
/// **Warning:** This is for debugging purposes only.
struct DebugDiagnosticsView: View {
    private let logger = LoggerService.shared
    private let authDiagnostics = AuthDiagnostics.shared
    @State private var logs: [String] = []
    @State private var isVerboseLoggingEnabled: Bool = false
    @State private var isAnchored: Bool = false
    @State private var nextLockTimeText: String = "—"
    @State private var completedGoals: Int = 0
    @State private var unlockMinutes: Int = 0
    @State private var appGroupStatusText: String = "—"
    @State private var appGroupPathText: String = "—"
    @State private var authSchemesText: String = "—"
    @State private var lastAuthErrorText: String = "—"
    @State private var lastAuthContextText: String = "—"
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Warning banner
                warningBanner
                
                // Controls section
                controlsSection

                // Anchor Status
                anchorStatusSection

                // App Group Diagnostics
                appGroupSection

                // Auth Diagnostics
                authDiagnosticsSection
                
                // Logs section
                logsSection
            }
        }
        .navigationTitle("Debug Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLogs()
            loadAnchorState()
            setupSubscriptions()
        }
    }
    
    // MARK: - Warning Banner
    
    private var warningBanner: some View {
        VStack(spacing: Theme.spacing) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppColors.warning)
                Text("Debug Mode")
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text("This screen is for debugging purposes only. Logs may contain technical information.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.spacing2)
        .frame(maxWidth: .infinity)
        .background(AppColors.warning.opacity(0.1))
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: Theme.spacing2) {
            // Verbose logging toggle
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacing / 2) {
                    Text("Verbose Logging")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Enable detailed logging for debugging")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isVerboseLoggingEnabled)
                    .labelsHidden()
                    .onChange(of: isVerboseLoggingEnabled) { newValue in
                        logger.setVerboseLogging(newValue)
                    }
            }
            .padding(Theme.spacing2)
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
            
            // Action buttons
            HStack(spacing: Theme.spacing) {
                Button(action: {
                    loadLogs()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacing)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(Theme.cornerRadiusMedium)
                }
                
                Button(action: {
                    logger.clearLogs()
                    loadLogs()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.error)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.spacing)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(Theme.cornerRadiusMedium)
                }
            }
        }
        .padding(Theme.spacing2)
    }

    private var anchorStatusSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Anchor Status")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)

            VStack(alignment: .leading, spacing: Theme.spacing2) {
                statusRow(label: "Locked", value: isAnchored ? "Yes" : "No")
                statusRow(label: "Next lock time", value: nextLockTimeText)
                statusRow(label: "Goals completed", value: "\(completedGoals)")
                statusRow(label: "Unlock minutes", value: "\(unlockMinutes)")
            }
            .padding(Theme.spacing2)
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
        .padding(.top, Theme.spacing2)
    }

    private var appGroupSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("App Group")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)

            VStack(alignment: .leading, spacing: Theme.spacing2) {
                statusRow(label: "Identifier", value: AppGroupStorage.appGroupIdentifier)
                statusRow(label: "Status", value: appGroupStatusText)
                statusRow(label: "Container", value: appGroupPathText)
            }
            .padding(Theme.spacing2)
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
        .padding(.top, Theme.spacing2)
    }

    private var authDiagnosticsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Auth Diagnostics")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)

            VStack(alignment: .leading, spacing: Theme.spacing2) {
                statusRow(label: "Bundle ID", value: authDiagnostics.bundleIdentifier)
                statusRow(label: "Google Client ID", value: authDiagnostics.googleClientIDMasked)
                statusRow(label: "Reverse Client ID", value: authDiagnostics.googleReverseClientIDMasked)
                statusRow(label: "URL Schemes", value: authSchemesText)
                statusRow(label: "Google Callback", value: authDiagnostics.hasGoogleCallbackScheme ? "OK" : "Missing")
                statusRow(label: "Callback URL", value: authDiagnostics.canConstructGoogleCallbackURL ? "OK" : "Invalid")
                statusRow(label: "Last Auth Context", value: lastAuthContextText)
                statusRow(label: "Last Auth Error", value: lastAuthErrorText)
            }
            .padding(Theme.spacing2)
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
        .padding(.top, Theme.spacing2)
    }
    
    // MARK: - Logs Section
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Recent Logs")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.spacing / 2) {
                    if logs.isEmpty {
                        Text("No logs available")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(Theme.spacing3)
                    } else {
                        ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                            LogEntryView(log: log)
                        }
                    }
                }
                .padding(Theme.spacing2)
            }
            .background(AppColors.secondaryBackground)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadLogs() {
        logs = logger.getRecentLogs(limit: 100)
    }

    private func loadAnchorState() {
        let shieldState = AppGroupStorage.shared.getShieldState()
        isAnchored = shieldState?.isBlocking ?? false

        if let progress = AppGroupStorage.shared.getDailyGoalProgress() {
            completedGoals = progress.completedGoalIds.count
            unlockMinutes = progress.earnedUnlockMinutesToday
        } else {
            completedGoals = 0
            unlockMinutes = 0
        }

        let time = AppGroupStorage.shared.getDailyAnchorTime() ?? DailyAnchorTime(hour: 0, minute: 0)
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0
        let todayLock = calendar.date(from: components) ?? now
        let next = now > todayLock ? calendar.date(byAdding: .day, value: 1, to: todayLock) ?? todayLock : todayLock
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        nextLockTimeText = formatter.string(from: next)

        if let containerURL = AppGroupStorage.shared.appGroupContainerURL() {
            appGroupStatusText = "OK"
            appGroupPathText = containerURL.path
        } else {
            appGroupStatusText = "Unavailable"
            appGroupPathText = "—"
        }

        let schemes = authDiagnostics.urlSchemes
        authSchemesText = schemes.isEmpty ? "—" : schemes.joined(separator: ", ")
        lastAuthErrorText = authDiagnostics.lastError ?? "—"
        lastAuthContextText = authDiagnostics.lastContext ?? "—"
    }
    
    private func setupSubscriptions() {
        // Load initial verbose logging state
        isVerboseLoggingEnabled = logger.isVerboseLoggingEnabled
        
        // Subscribe to verbose logging changes
        logger.verboseLoggingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isVerboseLoggingEnabled, on: self)
            .store(in: &cancellables)
        
        // Auto-refresh logs periodically
        Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [self] _ in
                loadLogs()
                loadAnchorState()
            }
            .store(in: &cancellables)
    }
}

private func statusRow(label: String, value: String) -> some View {
    HStack {
        Text(label)
            .font(AppTypography.body)
            .foregroundColor(AppColors.textSecondary)
        Spacer()
        Text(value)
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
    }
}

// MARK: - Log Entry View

private struct LogEntryView: View {
    let log: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacing) {
            // Log level indicator
            Circle()
                .fill(logLevelColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            // Log text
            Text(log)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textPrimary)
                .textSelection(.enabled)
            
            Spacer()
        }
        .padding(.vertical, Theme.spacing / 2)
        .padding(.horizontal, Theme.spacing)
        .background(AppColors.background)
        .cornerRadius(Theme.cornerRadiusSmall)
    }
    
    private var logLevelColor: Color {
        if log.contains("[ERROR]") {
            return AppColors.error
        } else if log.contains("[WARN]") {
            return AppColors.warning
        } else {
            return AppColors.primary
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DebugDiagnosticsView()
    }
}
