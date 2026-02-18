import Foundation

public struct V0DailyState: Codable, Hashable {
    public var completedGoalIDsToday: Set<UUID>
    public var lastResetLocalDate: Date
    public var dailyResetHour: Int
    public var dailyResetMinute: Int
    public var availableUnlockMinutesToday: Int
    public var lastUnlockMilestonePercent: Int

    public init(
        completedGoalIDsToday: Set<UUID> = [],
        lastResetLocalDate: Date = Date(timeIntervalSince1970: 0),
        dailyResetHour: Int = 0,
        dailyResetMinute: Int = 0,
        availableUnlockMinutesToday: Int = 0,
        lastUnlockMilestonePercent: Int = 0
    ) {
        self.completedGoalIDsToday = completedGoalIDsToday
        self.lastResetLocalDate = lastResetLocalDate
        self.dailyResetHour = dailyResetHour
        self.dailyResetMinute = dailyResetMinute
        self.availableUnlockMinutesToday = availableUnlockMinutesToday
        self.lastUnlockMilestonePercent = lastUnlockMilestonePercent
    }
}
