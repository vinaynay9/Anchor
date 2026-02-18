import Foundation

public enum V0UnlockMode: String, CaseIterable, Codable {
    case unlockAppsWhenAllTasksDone
    case unlockFixedTimePerGoal
    case unlockFixedTimePerPercentCompleted
    case unlockFixedAppsPerGoalCompletedForFixedTime

    public var title: String {
        switch self {
        case .unlockAppsWhenAllTasksDone:
            return "Unlock when all goals done"
        case .unlockFixedTimePerGoal:
            return "Fixed time per goal"
        case .unlockFixedTimePerPercentCompleted:
            return "Fixed time per percent"
        case .unlockFixedAppsPerGoalCompletedForFixedTime:
            return "Fixed apps per goal"
        }
    }
}
