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
