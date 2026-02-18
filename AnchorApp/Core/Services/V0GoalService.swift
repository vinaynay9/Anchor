import Foundation
import Shared

final class V0GoalService {
    static let shared = V0GoalService()

    private let storage = AppGroupStorage.shared

    private init() {}

    func loadGoals() -> [V0Goal] {
        storage.getV0Goals()
    }

    func saveGoals(_ goals: [V0Goal]) {
        storage.setV0Goals(goals)
    }

    func addGoal(title: String, categories: [V0GoalCategory]) {
        var goals = loadGoals()
        goals.append(V0Goal(title: title, categories: categories))
        saveGoals(goals)
    }

    func updateGoal(_ goal: V0Goal) {
        var goals = loadGoals()
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals(goals)
        }
    }

    func removeGoal(id: UUID) {
        var goals = loadGoals()
        goals.removeAll { $0.id == id }
        saveGoals(goals)
    }

    func isGoalCompletedToday(_ id: UUID) -> Bool {
        let state = storage.getV0DailyState()
        return state.completedGoalIDsToday.contains(id)
    }

    func markGoalCompletedToday(_ id: UUID) {
        var state = storage.getV0DailyState()
        state.completedGoalIDsToday.insert(id)
        storage.setV0DailyState(state)
    }

    func clearCompletedGoalsToday() {
        var state = storage.getV0DailyState()
        state.completedGoalIDsToday.removeAll()
        storage.setV0DailyState(state)
    }
}
