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
                .font(AppTypography.bodyBold)
                .foregroundColor(viewModel.selectedTab == tab ? AppColors.onPrimary : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacing)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                        .fill(viewModel.selectedTab == tab ? AppColors.anchorPrimary : Color.clear)
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
                .font(AppTypography.title2)
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
                            colors: [AppColors.anchorPrimary, AppColors.anchorAccent],
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
                .font(AppTypography.title2)
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
                        colors: [AppColors.anchorPrimary.opacity(0.3), AppColors.anchorAccent.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "app.fill")
                        .foregroundColor(AppColors.anchorAccent)
                )
            
            VStack(alignment: .leading, spacing: Theme.spacing / 2) {
                Text(app.displayName)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(app.category)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Text("\(app.totalMinutes)m")
                .font(AppTypography.bodyBold)
                .foregroundColor(AppColors.anchorAccent)
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
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Chart {
                ForEach(viewModel.weeklyUsage) { day in
                    LineMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.totalMinutes)
                    )
                    .foregroundStyle(AppColors.anchorAccent)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.totalMinutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppColors.anchorAccent.opacity(0.3),
                                AppColors.anchorAccent.opacity(0.05)
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
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.anchorAccent)
            }
            
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundColor(
                    viewModel.currentStreak > 0
                        ? AppColors.anchorAccent
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
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacing / 2) {
                    Text("Total Usage")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(viewModel.weeklyTotalMinutes) minutes")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Theme.spacing / 2) {
                    Text("Daily Average")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    let average = viewModel.weeklyUsage.isEmpty ? 0 : viewModel.weeklyTotalMinutes / viewModel.weeklyUsage.count
                    Text("\(average) minutes")
                        .font(AppTypography.title3)
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
                .font(.system(size: 64, weight: .light))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            Text("No Insights Available")
                .font(AppTypography.title2)
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
