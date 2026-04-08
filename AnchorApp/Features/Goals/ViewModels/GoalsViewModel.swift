import Foundation
import Shared

@MainActor
final class GoalsViewModel: ObservableObject {
    @Published var goals: [Shared.Goal] = []
    @Published var progress: DailyGoalProgress = DailyGoalProgress(date: "")
    @Published var isAnchored: Bool = false
    @Published var completionFeedback: String?

    // Add goal sheet state
    @Published var showAddGoalSheet = false
    @Published var newGoalTitle = ""
    @Published var newGoalCategory: GoalCategory = .other

    private let dailyGoalService = DailyGoalService.shared

    var completedCount: Int {
        progress.completedGoalIds.count
    }

    var totalCount: Int {
        max(goals.count, 0)
    }

    var progressText: String {
        "\(completedCount) of \(max(totalCount, 0)) goals completed"
    }

    func load() async {
        goals = await dailyGoalService.loadGoals()
        progress = dailyGoalService.loadProgress()
        isAnchored = dailyGoalService.isAnchored()
    }

    func complete(goal: Shared.Goal) async {
        let previousCompletion = progress.lastCompletionTimestamp
        progress = await dailyGoalService.markGoalCompleted(goalId: goal.id)
        isAnchored = dailyGoalService.isAnchored()

        if let previous = previousCompletion, Date().timeIntervalSince(previous) < 120 {
            completionFeedback = "Be honest—future you will know."
        } else {
            completionFeedback = "Proud of you. Keep going."
        }
    }

    func isGoalCompleted(_ goal: Shared.Goal) -> Bool {
        progress.completedGoalIds.contains(goal.id)
    }

    func delete(goal: Shared.Goal) async {
        await dailyGoalService.removeGoal(id: goal.id)
        await load()
    }

    func addGoalFromSheet() async {
        let title = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        await dailyGoalService.addGoal(title: title, category: newGoalCategory)
        newGoalTitle = ""
        newGoalCategory = .other
        showAddGoalSheet = false
        await load()
    }

    func resetProgress() {
        AppGroupStorage.shared.setDailyGoalProgress(nil)
        progress = dailyGoalService.loadProgress()
    }
}
