import SwiftUI
import Shared

struct V0GoalsListView: View {
    let goals: [V0Goal]
    let completedGoalIDs: Set<UUID>
    let onSelectGoal: (V0Goal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goals")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            ForEach(goals) { goal in
                Button(action: { onSelectGoal(goal) }) {
                    SolidCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)

                                if !goal.categories.isEmpty {
                                    Text(goal.categories.map { $0.displayName }.joined(separator: ", "))
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }

                            Spacer()

                            Image(systemName: completedGoalIDs.contains(goal.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(completedGoalIDs.contains(goal.id) ? AppColors.accent : AppColors.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            if goals.isEmpty {
                Text("No goals yet. Complete onboarding to add goals.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}
