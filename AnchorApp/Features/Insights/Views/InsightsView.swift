import SwiftUI
import Charts

struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Error Banner
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.horizontal, Theme.padding)
                    .padding(.top, Theme.spacing)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Tab Selector
                tabSelector
                    .padding(.horizontal, Theme.padding)
                    .padding(.top, Theme.spacing)
                
                // Content
                if viewModel.isLoading && !viewModel.hasData {
                    LoadingView(message: "Loading insights...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.hasData {
                    ScrollView {
                        VStack(spacing: Theme.spacing3) {
                            if viewModel.selectedTab == .daily {
                                dailyView
                            } else {
                                weeklyView
                            }
                        }
                        .padding(Theme.padding)
                    }
                } else {
                    emptyStateView
                }
            }
        }
        .navigationTitle("Insights")
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedTab)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoading)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: Theme.spacing) {
            tabButton(title: "Daily", tab: .daily)
            tabButton(title: "Weekly", tab: .weekly)
        }
        .padding(Theme.spacing / 2)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private func tabButton(title: String, tab: InsightsViewModel.InsightsTab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectTab(tab)
            }
        }) {
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(viewModel.selectedTab == tab ? AppColors.onPrimary : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacing)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                        .fill(viewModel.selectedTab == tab ? AppColors.primary : Color.clear)
                )
        }
    }
    
    // MARK: - Daily View
    
    private var dailyView: some View {
        VStack(spacing: Theme.spacing3) {
            // Category Usage Chart
            if !viewModel.categoryUsage.isEmpty {
                categoryUsageChart
            }
            
            // Top Distracting Apps
            if !viewModel.topDistractingApps.isEmpty {
                topDistractingAppsSection
            }
        }
    }
    
    private var categoryUsageChart: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Usage by Category")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
            
            Chart {
                ForEach(Array(viewModel.categoryUsage.keys.sorted()), id: \.self) { category in
                    let minutes = viewModel.categoryUsage[category] ?? 0
                    BarMark(
                        x: .value("Category", category),
                        y: .value("Minutes", minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(Theme.cornerRadiusSmall)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)m")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let category = value.as(String.self) {
                            Text(category)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
        }
        .padding(Theme.padding)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
    
    private var topDistractingAppsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Top Distracting Apps")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
            
            ForEach(viewModel.topDistractingApps) { app in
                appUsageRow(app: app)
            }
        }
        .padding(Theme.padding)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
    
    private func appUsageRow(app: AppUsageSummary) -> some View {
        HStack(spacing: Theme.spacing) {
            // App icon placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.primary.opacity(0.3), AppColors.accent.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "app.fill")
                        .foregroundColor(AppColors.accent)
                )
            
            VStack(alignment: .leading, spacing: Theme.spacing / 2) {
                Text(app.displayName)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(app.category)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Text("\(app.totalMinutes)m")
                .font(AppTypography.body)
                .foregroundColor(AppColors.accent)
        }
        .padding(.vertical, Theme.spacing / 2)
    }
    
    // MARK: - Weekly View
    
    private var weeklyView: some View {
        VStack(spacing: Theme.spacing3) {
            // Weekly Trend Chart
            if !viewModel.weeklyUsage.isEmpty {
                weeklyTrendChart
            }
            
            // Streak Indicator
            streakIndicator
            
            // Weekly Summary
            weeklySummary
        }
    }
    
    private var weeklyTrendChart: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("7-Day Trend")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
            
            Chart {
                ForEach(viewModel.weeklyUsage) { day in
                    LineMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.totalMinutes)
                    )
                    .foregroundStyle(AppColors.accent)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.totalMinutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppColors.accent.opacity(0.3),
                                AppColors.accent.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)m")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel {
                        Text(value.as(Date.self)?.formatted(.dateTime.weekday(.abbreviated)) ?? "")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(Theme.padding)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
    
    private var streakIndicator: some View {
        HStack(spacing: Theme.spacing) {
            VStack(alignment: .leading, spacing: Theme.spacing / 2) {
                Text("Current Streak")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("\(viewModel.currentStreak) days")
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.accent)
            }
            
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(AppTypography.sectionHeader)
                .foregroundColor(
                    viewModel.currentStreak > 0
                        ? AppColors.accent
                        : AppColors.textSecondary.opacity(0.3)
                )
        }
        .padding(Theme.padding)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
    
    private var weeklySummary: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Weekly Summary")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacing / 2) {
                    Text("Total Usage")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(viewModel.weeklyTotalMinutes) minutes")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Theme.spacing / 2) {
                    Text("Daily Average")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    let average = viewModel.weeklyUsage.isEmpty ? 0 : viewModel.weeklyTotalMinutes / viewModel.weeklyUsage.count
                    Text("\(average) minutes")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(Theme.padding)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.spacing3) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(AppTypography.screenTitle).fontWeight(.light)
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            Text("No Insights Available")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Usage data will appear here once you start using the app")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.padding)
            
            if viewModel.errorMessage != nil {
                Button(action: {
                    viewModel.retry()
                }) {
                    Text("Retry")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.padding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.padding * 2)
    }
}
import SwiftUI
import Shared

// MARK: - Stats View
// 4 sections: Today, Averages, Top Distractions, Streaks

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.brandBackgroundDark, AppColors.surface.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.spacing3) {
                    Spacer().frame(height: Theme.spacing2)
                    todayCard
                    averagesCard
                    topDistractionsCard
                    streaksCard
                    Spacer().frame(height: Theme.spacing3)
                }
                .padding(.horizontal, Theme.spacing3)
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            statsHeader
        }
        .task {
            await viewModel.load()
            if reduceMotion { showContent = true }
            else { withAnimation(AppMotion.gentleSpring.delay(0.1)) { showContent = true } }
        }
    }

    // MARK: - Custom header

    private var statsHeader: some View {
        Text("Stats")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.spacing3)
            .padding(.top, 56)
            .padding(.bottom, Theme.spacing)
            .background(AppColors.brandBackgroundDark.opacity(0.95))
    }

    // MARK: - Section 1: Today

    private var todayCard: some View {
        StatsCard(title: "Today", icon: "sun.max.fill", iconColor: .yellow) {
            if !viewModel.hasAnyData {
                emptyState("Complete your first day to start tracking.")
            } else {
                HStack(spacing: 0) {
                    statItem(value: viewModel.todayLockedFormatted, label: "Locked")
                    divider
                    statItem(value: "\(viewModel.todayShieldHits)", label: "Shield Hits")
                    divider
                    statItem(
                        value: "\(viewModel.todayGoalsCompleted)/\(viewModel.todayGoalsTotal)",
                        label: "Goals"
                    )
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
    }

    // MARK: - Section 2: Averages

    private var averagesCard: some View {
        StatsCard(title: "Averages", icon: "chart.line.uptrend.xyaxis", iconColor: AppColors.accent) {
            if viewModel.avgLockedSeconds == nil {
                emptyState("Complete a few days to see averages.")
            } else {
                VStack(spacing: Theme.spacing2) {
                    avgRow(label: "Avg lock time / day", value: viewModel.avgLockedFormatted, icon: "lock.fill")
                    Divider().background(AppColors.border.opacity(0.30))
                    avgRow(label: "Avg goals / day", value: viewModel.avgGoalsFormatted, icon: "target")
                    Divider().background(AppColors.border.opacity(0.30))
                    avgRow(label: "Avg shield hits / day", value: viewModel.avgShieldHitsFormatted, icon: "shield.slash.fill")
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
        .animation(AppMotion.gentleSpring.delay(0.05), value: showContent)
    }

    // MARK: - Section 3: Top Distractions

    private var topDistractionsCard: some View {
        StatsCard(title: "Top Distractions", icon: "exclamationmark.shield.fill", iconColor: .orange) {
            if viewModel.topCategories.isEmpty {
                emptyState("No shield hits recorded yet.")
            } else {
                VStack(alignment: .leading, spacing: Theme.spacing2) {
                    ForEach(Array(viewModel.topCategories.prefix(5).enumerated()), id: \.offset) { idx, item in
                        CategoryBarRow(
                            rank: idx + 1,
                            name: item.category,
                            hits: item.hits,
                            maxHits: viewModel.topCategoryMax
                        )
                    }
                }
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
        .animation(AppMotion.gentleSpring.delay(0.10), value: showContent)
    }

    // MARK: - Section 4: Streaks

    private var streaksCard: some View {
        StatsCard(title: "Streaks", icon: "flame.fill", iconColor: .orange) {
            HStack(spacing: 0) {
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 28))
                        Text("\(viewModel.currentStreak)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(viewModel.currentStreak > 0 ? AppColors.textPrimary : AppColors.textSecondary)
                    }
                    Text("Current Streak")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(viewModel.currentStreak == 1 ? "1 day" : "\(viewModel.currentStreak) days")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary.opacity(0.70))
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(AppColors.border.opacity(0.30))
                    .frame(width: 1, height: 60)

                VStack(spacing: 6) {
                    Text("\(viewModel.longestStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Longest Streak")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(viewModel.longestStreak == 1 ? "1 day" : "\(viewModel.longestStreak) days")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary.opacity(0.70))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Theme.spacing)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
        .animation(AppMotion.gentleSpring.delay(0.15), value: showContent)
    }

    // MARK: - Reusable sub-views

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColors.border.opacity(0.30))
            .frame(width: 1, height: 44)
    }

    private func avgRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.accent.opacity(0.75))
                .frame(width: 22)
            Text(label)
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private func emptyState(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary.opacity(0.50))
            Text(message)
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary.opacity(0.70))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - StatsCard container

private struct StatsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            // Header row
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
            }
            content()
        }
        .padding(Theme.spacing3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.border.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

// MARK: - Category bar row

private struct CategoryBarRow: View {
    let rank: Int
    let name: String
    let hits: Int
    let maxHits: Int

    private var barFraction: Double {
        maxHits > 0 ? Double(hits) / Double(maxHits) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(rank). \(name)")
                    .font(AppTypography.helper)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(hits)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.border.opacity(0.25))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accent, AppColors.accent.opacity(0.60)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * barFraction, height: 6)
                        .animation(AppMotion.standard, value: barFraction)
                }
            }
            .frame(height: 6)
        }
    }
}
