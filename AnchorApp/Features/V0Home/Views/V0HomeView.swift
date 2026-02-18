import SwiftUI
import Shared

struct V0HomeView: View {
    @StateObject private var viewModel = V0HomeViewModel()
    @State private var selectedGoal: V0Goal?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statusCard

                    V0UsageSummaryCard()

                    V0GoalsListView(
                        goals: viewModel.goals,
                        completedGoalIDs: viewModel.completedGoalIDs
                    ) { goal in
                        selectedGoal = goal
                    }
                }
                .padding()
            }
            .navigationTitle("Anchor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Settings") {
                        V0SettingsView()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .applyV0Theme()
            .sheet(item: $selectedGoal) { goal in
                V0GoalCompleteView(goal: goal)
            }
        }
    }

    private var statusCard: some View {
        SolidCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.isLocked ? "Locked" : "Unlocked")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(viewModel.isLocked ? "Complete goals to unlock your selected apps." : "Enjoy your unlocked time.")
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
