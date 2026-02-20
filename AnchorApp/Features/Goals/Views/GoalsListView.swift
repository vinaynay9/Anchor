import SwiftUI
import Shared

struct GoalsListView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var selectedGoal: Shared.Goal?
    @State private var showFeedback = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    header

                    progressCard

                    goalsCard
                }
                .padding(.vertical, Theme.spacing4)
            }
        }
        .sheet(item: $selectedGoal) { goal in
            GoalCompletionDetailView(goal: goal) {
                Task {
                    await viewModel.complete(goal: goal)
                    showFeedback = viewModel.completionFeedback != nil
                }
            }
        }
        .alert("", isPresented: $showFeedback, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(viewModel.completionFeedback ?? "")
        })
        .task { await viewModel.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text(viewModel.isAnchored ? "You are Anchored" : "Not Anchored")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.textPrimary)

            Text("Complete your goals to Break Anchor.")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.spacing3)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Today")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)

            Text(viewModel.progressText)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)

            ProgressView(value: Double(viewModel.completedCount), total: Double(max(viewModel.totalCount, 1)))
                .tint(AppColors.accent)
        }
        .padding(Theme.spacing3)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.accent.opacity(0.12), radius: 10, x: 0, y: 4)
        .padding(.horizontal, Theme.spacing3)
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Goals to complete")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)

            ForEach(viewModel.goals) { goal in
                Button(action: { selectedGoal = goal }) {
                    HStack(spacing: Theme.spacing2) {
                        Image(systemName: viewModel.isGoalCompleted(goal) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(viewModel.isGoalCompleted(goal) ? AppColors.accent : AppColors.textTertiary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.title)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)

                            Text(goal.category.displayName)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, Theme.spacing)
                }
                .buttonStyle(PlainButtonStyle())

                if goal.id != viewModel.goals.last?.id {
                    Divider().background(AppColors.border)
                }
            }
        }
        .padding(Theme.spacing3)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.accent.opacity(0.12), radius: 10, x: 0, y: 4)
        .padding(.horizontal, Theme.spacing3)
    }
}
