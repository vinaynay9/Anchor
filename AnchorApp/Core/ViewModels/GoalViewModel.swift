import SwiftUI

@MainActor
final class GoalViewModel: ObservableObject {
    @Published private(set) var goals: [Goal] = []

    private let goalService: GoalServiceProtocol

    init(goalService: GoalServiceProtocol = GoalService.shared) {
        self.goalService = goalService
        goals = goalService.loadGoals()
    }

    func reload() {
        goals = goalService.loadGoals()
    }

    func addGoal(_ name: String) {
        goalService.addGoal(name)
        reload()
    }

    func toggleGoal(_ goal: Goal) {
        goalService.toggleGoal(goal)
        reload()
    }

    func resetGoalsDaily() {
        goalService.resetGoalsDaily()
        reload()
    }

    func getCompletedCount() -> Int {
        goalService.getCompletedCount()
    }

    func getTotalCount() -> Int {
        goalService.getTotalCount()
    }
}
