import SwiftUI
import Shared

struct V0GoalSetupView: View {
    @State private var goals: [V0Goal] = AppGroupStorage.shared.getV0Goals()

    let onContinue: () -> Void

    private let goalService = V0GoalService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Set your goals")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Add goals you want to complete before unlocking apps.")
                    .foregroundColor(AppColors.textSecondary)

                ForEach($goals) { $goal in
                    SolidCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Read 20 pages", text: $goal.title)
                                .textFieldStyle(AppTextFieldStyle())

                            Text("Categories")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                                ForEach(V0GoalCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        toggleCategory(category, for: goal.id)
                                    }) {
                                        Text(category.displayName)
                                            .font(.system(size: 12, weight: .semibold))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 8)
                                            .background(isCategorySelected(category, in: goal) ? AppColors.primary : AppColors.surfaceElevated)
                                            .foregroundColor(isCategorySelected(category, in: goal) ? AppColors.textPrimary : AppColors.textSecondary)
                                            .cornerRadius(8)
                                    }
                                }
                            }

                            if goals.count > 1 {
                                Button(role: .destructive) {
                                    removeGoal(id: goal.id)
                                } label: {
                                    Text("Remove goal")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                        }
                    }
                }

                Button(action: addGoal) {
                    Text("Add another goal")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: saveAndContinue) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
                .opacity(canContinue ? 1.0 : 0.6)
                .padding(.top, 12)
            }
            .padding()
        }
        .applyV0Theme()
        .onAppear {
            if goals.isEmpty {
                goals = [V0Goal(title: "", categories: [])]
            }
        }
    }

    private var canContinue: Bool {
        let hasTitles = goals.allSatisfy { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return !goals.isEmpty && hasTitles
    }

    private func addGoal() {
        goals.append(V0Goal(title: "", categories: []))
    }

    private func removeGoal(id: UUID) {
        goals.removeAll { $0.id == id }
    }

    private func saveAndContinue() {
        goalService.saveGoals(goals)
        onContinue()
    }

    private func toggleCategory(_ category: V0GoalCategory, for goalId: UUID) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        if goals[index].categories.contains(category) {
            goals[index].categories.removeAll { $0 == category }
        } else {
            goals[index].categories.append(category)
        }
    }

    private func isCategorySelected(_ category: V0GoalCategory, in goal: V0Goal) -> Bool {
        goal.categories.contains(category)
    }
}
