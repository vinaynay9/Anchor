import Foundation
import Shared

// MARK: - Goal Model
struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), name: String, isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
    }
}

// MARK: - Goal Service Protocol
protocol GoalServiceProtocol {
    func loadGoals() -> [Goal]
    func saveGoals(_ goals: [Goal])
    func addGoal(_ name: String)
    func toggleGoal(_ goal: Goal)
    func deleteGoal(_ goal: Goal)
    func resetGoalsDaily()
    func getCompletedCount() -> Int
    func getTotalCount() -> Int
    func areAllGoalsCompleted() -> Bool
}

// MARK: - Goal Service
class GoalService: GoalServiceProtocol {
    static let shared = GoalService()
    
    private let goalsKey = "dailyGoals"
    
    // MARK: - Service Rewrite Decision
    // GoalService is REWRITTEN to be simple goal gating (no habit tracking, no analytics).
    private init() {}
    
    // MARK: - Load Goals
    func loadGoals() -> [Goal] {
        guard let data = UserDefaults.standard.data(forKey: goalsKey),
              let goals = try? JSONDecoder().decode([Goal].self, from: data) else {
            return []
        }
        return goals
    }
    
    // MARK: - Save Goals
    func saveGoals(_ goals: [Goal]) {
        guard let data = try? JSONEncoder().encode(goals) else { return }
        UserDefaults.standard.set(data, forKey: goalsKey)
    }
    
    // MARK: - Add Goal
    func addGoal(_ name: String) {
        var goals = loadGoals()
        let newGoal = Goal(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        goals.append(newGoal)
        saveGoals(goals)
    }
    
    // MARK: - Toggle Goal
    func toggleGoal(_ goal: Goal) {
        var goals = loadGoals()
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].isCompleted.toggle()
            saveGoals(goals)
        }
    }
    
    // MARK: - Delete Goal
    func deleteGoal(_ goal: Goal) {
        var goals = loadGoals()
        goals.removeAll { $0.id == goal.id }
        saveGoals(goals)
    }
    
    // MARK: - Manual Reset (kept for compatibility)
    func resetGoalsDaily() {
        var goals = loadGoals()
        for index in goals.indices {
            goals[index].isCompleted = false
        }
        saveGoals(goals)
    }
    
    // MARK: - Helper Methods
    func getCompletedCount() -> Int {
        loadGoals().filter { $0.isCompleted }.count
    }
    
    func getTotalCount() -> Int {
        loadGoals().count
    }
    
    func areAllGoalsCompleted() -> Bool {
        let goals = loadGoals()
        return !goals.isEmpty && goals.allSatisfy { $0.isCompleted }
    }
}
