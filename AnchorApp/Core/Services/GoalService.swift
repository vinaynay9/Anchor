import Foundation

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
    private let lastResetDateKey = "lastGoalsResetDate"
    
    private init() {
        // Reset goals daily if needed
        resetGoalsDailyIfNeeded()
    }
    
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
    
    // MARK: - Reset Goals Daily
    func resetGoalsDaily() {
        var goals = loadGoals()
        // Reset completion status but keep goals
        for index in goals.indices {
            goals[index].isCompleted = false
        }
        saveGoals(goals)
        UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
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
    
    // MARK: - Private Helpers
    private func resetGoalsDailyIfNeeded() {
        let calendar = Calendar.current
        let lastResetDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date
        
        if let lastReset = lastResetDate {
            // Check if it's a new day
            if !calendar.isDateInToday(lastReset) {
                resetGoalsDaily()
            }
        } else {
            // First time - set reset date but don't reset
            UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
        }
    }
}

