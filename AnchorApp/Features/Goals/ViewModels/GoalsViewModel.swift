import Foundation
import Shared

@MainActor
final class GoalsViewModel: ObservableObject {
    @Published var goals: [Shared.Goal] = []
    @Published var progress: DailyGoalProgress = DailyGoalProgress(date: "")
    @Published var isAnchored: Bool = false
    @Published var completionFeedback: String?

    private let dailyGoalService = DailyGoalService.shared

    var completedCount: Int {
        progress.completedGoalIds.count
    }

    var totalCount: Int {
        max(goals.count, 0)
    }

    var progressText: String {
        "\(completedCount) / \(max(totalCount, 0)) complete"
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
}
