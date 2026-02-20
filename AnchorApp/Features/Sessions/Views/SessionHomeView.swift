import SwiftUI
import Shared

struct SessionHomeView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @StateObject private var viewModel = SessionViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    header
                        .padding(.horizontal, Theme.padding)
                        .padding(.top, Theme.padding)

                // Error Banner
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.horizontal, Theme.padding)
                    .padding(.top, Theme.spacing)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content
                statusCard
                    .padding(.horizontal, Theme.padding)

                goalsProgressCard
                    .padding(.horizontal, Theme.padding)

                usageSummaryCard
                    .padding(.horizontal, Theme.padding)

                if !viewModel.isAnchored {
                    lockCTA
                        .padding(.horizontal, Theme.padding)
                }
            }
            .padding(.bottom, Theme.spacing4)
        }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .motion(AppMotion.standard, reduceMotion: reduceMotion, value: viewModel.activeSession != nil)
        .motion(AppMotion.standard, reduceMotion: reduceMotion, value: viewModel.isLoading)
        .onAppear { viewModel.loadActiveSession() }
        .task { await viewModel.loadDashboardData() }
    }

    private var header: some View {
        HStack(spacing: Theme.spacing) {
            Image("Anchor_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Anchor")
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.primary)

                Text("Stay Anchored")
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text(viewModel.isAnchored ? "Anchored" : "Not Anchored")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)

            Text(viewModel.isAnchored ? "Complete your goals to Break Anchor." : "Lock selected apps until your goals are complete.")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(Theme.spacing3)
        .background(cardBackground)
    }

    private var goalsProgressCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Today’s goals")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)

            Text("\(viewModel.goalsCompleted) / \(max(viewModel.goalsTotal, 0)) complete")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)

            ProgressView(value: Double(viewModel.goalsCompleted), total: Double(max(viewModel.goalsTotal, 1)))
                .tint(AppColors.accent)
        }
        .padding(Theme.spacing3)
        .background(cardBackground)
    }

    private var usageSummaryCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Today’s usage")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)

            if let error = viewModel.usageError {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else if viewModel.usageSummaries.isEmpty {
                Text("No usage data yet.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                ForEach(viewModel.usageSummaries.prefix(3)) { summary in
                    HStack {
                        Text(summary.displayName)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(summary.totalMinutes) min")
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(Theme.spacing3)
        .background(cardBackground)
    }

    private var lockCTA: some View {
        Button(action: {
            HapticFeedback.selectionChanged()
            coordinator.navigateToSessionSetup()
        }) {
            Text("Lock & Anchor")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryPressableButtonStyle())
        .padding(.top, Theme.spacing)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
            .fill(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                    .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: AppColors.accent.opacity(0.12), radius: 10, x: 0, y: 4)
    }
    
    
}
