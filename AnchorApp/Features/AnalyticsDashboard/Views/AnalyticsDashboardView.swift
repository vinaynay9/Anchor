import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsDashboardViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    headerSection
                    
                    if let data = viewModel.dashboardData {
                        summarySection(data.summary)
                        impulseSection(data.impulse)
                        disciplineSection(data.discipline)
                        socialSection(data.social)
                        challengesSection(data.challenges)
                        networkSection(data.network)
                        silentSuccessSection(data.silentSuccess)
                    } else {
                        LoadingView(message: "Loading analytics...")
                    }
                }
                .padding(.horizontal, Theme.spacing2)
                .padding(.vertical, Theme.spacing3)
            }
        }
        .navigationTitle("Founder Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Behavioral Metrics")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Privacy-safe, aggregate signals for product impact.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            if let latest = viewModel.dashboardData?.latestEventAt {
                Text("Last updated \(relativeTime(from: latest))")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                Text("No analytics data yet")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Picker("Range", selection: $viewModel.selectedRange) {
                ForEach(AnalyticsRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(Theme.spacing2)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }

    private func summarySection(_ summary: AnalyticsSummaryMetrics) -> some View {
        VStack(spacing: Theme.spacing) {
            HStack(spacing: Theme.spacing) {
                summaryCard(
                    title: "Shield hits today",
                    value: "\(summary.shieldHitsToday)",
                    subtitle: "Yesterday \(summary.shieldHitsYesterday)",
                    trend: trendForDelta(current: summary.shieldHitsToday, previous: summary.shieldHitsYesterday)
                )
                summaryCard(
                    title: "Emergency unanchors",
                    value: "\(summary.emergencyUnanchorsLast7Days)",
                    subtitle: "Last 7 days"
                )
            }
            summaryCard(
                title: "Median pledge completion",
                value: formatSeconds(summary.medianPledgeCompletionSecondsLast7Days),
                subtitle: "7-day trend",
                trend: summary.medianPledgeCompletionTrend
            )
        }
    }
    
    private func impulseSection(_ metrics: ImpulseMetrics) -> some View {
        sectionCard(title: "Impulse & Temptation") {
            if metrics.shieldHitsPerDay.isEmpty && metrics.shieldHitsByHour.allSatisfy({ $0.value == 0 }) {
                sectionEmptyState()
            }
            chartCard(title: "Shield Hits / Day", points: metrics.shieldHitsPerDay)
            
            Chart(metrics.shieldHitsByHour) { point in
                BarMark(
                    x: .value("Hour", point.hour),
                    y: .value("Count", point.value)
                )
                .foregroundStyle(AppColors.textSecondary)
            }
            .frame(height: 160)
            
            metricRow(
                title: "Median impulse recovery",
                value: formatSeconds(metrics.medianImpulseRecoverySeconds)
            )
            metricRow(
                title: "Median shield → anchor",
                value: formatSeconds(metrics.medianShieldToAnchorSeconds)
            )
            metricRow(
                title: "Interaction pattern",
                value: metrics.interactionPattern
            )
            metricRow(
                title: "Shield hits trend",
                value: trendValue(metrics.trend),
                trend: metrics.trend
            )
            metricRow(
                title: "App opens (anchored/free)",
                value: "\(metrics.appOpensAnchored) / \(metrics.appOpensFree)"
            )
        }
    }
    
    private func disciplineSection(_ metrics: DisciplineMetrics) -> some View {
        sectionCard(title: "Discipline & Habit Formation") {
            if metrics.pledgeCompletionsPerDay.isEmpty && metrics.emergencyUnanchorsPerDay.isEmpty {
                sectionEmptyState()
            }
            chartCard(title: "Pledge Completions / Day", points: metrics.pledgeCompletionsPerDay)
            chartCard(title: "Emergency Unanchors / Day", points: metrics.emergencyUnanchorsPerDay)
            
            metricRow(
                title: "Median completion latency",
                value: formatSeconds(metrics.medianCompletionLatencySeconds)
            )
            metricRow(
                title: "Days since last emergency",
                value: metrics.timeSinceLastEmergencyDays.map(String.init) ?? "—"
            )
        }
    }
    
    private func socialSection(_ metrics: SocialMetrics) -> some View {
        sectionCard(title: "Social Gravity") {
            if metrics.profileViewsPerDay.isEmpty && metrics.proofSubmissionsPerDay.isEmpty {
                sectionEmptyState()
            }
            chartCard(title: "Profile Views / Day", points: metrics.profileViewsPerDay)
            chartCard(title: "Proof Submissions / Day", points: metrics.proofSubmissionsPerDay)
        }
    }
    
    private func challengesSection(_ metrics: ChallengesMetrics) -> some View {
        sectionCard(title: "Challenges & Adaptation") {
            if metrics.challengeCreatesPerDay.isEmpty &&
                metrics.challengeCompletionsPerDay.isEmpty &&
                metrics.challengeConcessionsPerDay.isEmpty {
                sectionEmptyState()
            }
            chartCard(title: "Challenges Created / Day", points: metrics.challengeCreatesPerDay)
            chartCard(title: "Challenges Completed / Day", points: metrics.challengeCompletionsPerDay)
            chartCard(title: "Challenges Conceded / Day", points: metrics.challengeConcessionsPerDay)
        }
    }
    
    private func networkSection(_ metrics: NetworkMetrics) -> some View {
        sectionCard(title: "Network Effects") {
            if metrics.invitesSentPerDay.isEmpty && metrics.invitesAcceptedPerDay.isEmpty {
                sectionEmptyState()
            }
            chartCard(title: "Invites Sent / Day", points: metrics.invitesSentPerDay)
            chartCard(title: "Invites Accepted / Day", points: metrics.invitesAcceptedPerDay)
        }
    }
    
    private func silentSuccessSection(_ metrics: SilentSuccessMetrics) -> some View {
        sectionCard(title: "Silent Success") {
            metricRow(title: "Low-interaction days", value: "\(metrics.lowInteractionDays)")
            metricRow(
                title: "Zero emergency unanchors",
                value: metrics.zeroEmergencyUnanchors ? "Yes" : "No"
            )
            metricRow(
                title: "Longest no-interaction streak",
                value: "\(metrics.longestNoInteractionStreakDays) days"
            )
        }
    }

    private func summaryCard(title: String, value: String, subtitle: String, trend: AnalyticsTrend? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 6) {
                if let trend = trend {
                    TrendBadge(trend: trend)
                }
                Text(value)
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
            }
            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(Theme.spacing2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
    
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text(title.uppercased())
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            
            content()
        }
        .padding(Theme.spacing2)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
    
    private func chartCard(title: String, points: [AnalyticsTimeSeriesPoint]) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            
            if points.isEmpty {
                Text("No data")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(height: 120)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Count", point.value)
                    )
                    .foregroundStyle(AppColors.textPrimary)
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Count", point.value)
                    )
                    .foregroundStyle(AppColors.textSecondary.opacity(0.15))
                }
                .frame(height: 160)
            }
        }
    }
    
    private func metricRow(title: String, value: String, trend: AnalyticsTrend? = nil) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            if let trend = trend {
                TrendBadge(trend: trend)
            }
            Text(value)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    private func formatSeconds(_ seconds: Double?) -> String {
        guard let seconds else { return "—" }
        if seconds < 60 {
            return "\(Int(seconds))s"
        }
        let minutes = Int(seconds / 60)
        return "\(minutes)m"
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func sectionEmptyState() -> some View {
        Text("No data in this range.")
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func trendForDelta(current: Int, previous: Int) -> AnalyticsTrend {
        guard previous > 0 else {
            return AnalyticsTrend(direction: current > 0 ? .up : .flat, deltaPercent: nil)
        }
        let delta = Double(current - previous) / Double(previous)
        let direction: AnalyticsTrendDirection
        if abs(delta) < 0.05 {
            direction = .flat
        } else {
            direction = delta > 0 ? .up : .down
        }
        return AnalyticsTrend(direction: direction, deltaPercent: delta)
    }
    
    private func trendValue(_ trend: AnalyticsTrend) -> String {
        guard let delta = trend.deltaPercent else { return "—" }
        let percent = Int(delta * 100)
        return "\(percent)%"
    }
}

struct TrendBadge: View {
    let trend: AnalyticsTrend
    
    var body: some View {
        let symbol: String
        switch trend.direction {
        case .up: symbol = "arrow.up"
        case .down: symbol = "arrow.down"
        case .flat: symbol = "arrow.right"
        }
        return Image(systemName: symbol)
            .font(AppTypography.caption).fontWeight(.semibold)
            .foregroundColor(AppColors.textSecondary)
    }
}
