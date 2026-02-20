import Foundation

public enum UnlockPolicyMode: String, Codable, Hashable, CaseIterable {
    case unlockAppsWhenAllTasksDone
    case unlockFixedTimePerGoal
    case unlockFixedTimePerPercentCompleted
    case unlockFixedAppsPerGoalCompletedForFixedTime
}

public struct UnlockPolicyConfig: Codable, Hashable {
    public var mode: UnlockPolicyMode
    public var timeIntervalMinutes: Int?
    public var percentStep: Int?

    public init(mode: UnlockPolicyMode, timeIntervalMinutes: Int? = nil, percentStep: Int? = nil) {
        self.mode = mode
        self.timeIntervalMinutes = timeIntervalMinutes
        self.percentStep = percentStep
    }
}
