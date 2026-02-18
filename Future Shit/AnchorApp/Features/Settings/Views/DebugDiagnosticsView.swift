import SwiftUI
import Combine

/// Debug diagnostics view for viewing logs and toggling verbose logging.
/// **Warning:** This is for debugging purposes only.
struct DebugDiagnosticsView: View {
    private let logger = LoggerService.shared
    @State private var logs: [String] = []
    @State private var isVerboseLoggingEnabled: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Warning banner
                warningBanner
                
                // Controls section
                controlsSection
                
                // Logs section
                logsSection
            }
        }
        .navigationTitle("Debug Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLogs()
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
                    .font(AppTypography.headline)
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
                    .foregroundColor(AppColors.anchorPrimary)
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
    
    // MARK: - Logs Section
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Recent Logs")
                .font(AppTypography.headline)
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
            }
            .store(in: &cancellables)
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
                .font(.system(.caption, design: .monospaced))
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
            return AppColors.anchorPrimary
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DebugDiagnosticsView()
    }
}

