import Foundation

public struct DailyGoalProgress: Codable, Hashable {
    public let date: String
    public var completedGoalIds: [UUID]
    public var earnedUnlockMinutesToday: Int
    public var lastCompletionTimestamp: Date?
    public var lastUnlockedPercent: Int

    public init(
        date: String,
        completedGoalIds: [UUID] = [],
        earnedUnlockMinutesToday: Int = 0,
        lastCompletionTimestamp: Date? = nil,
        lastUnlockedPercent: Int = 0
    ) {
        self.date = date
        self.completedGoalIds = completedGoalIds
        self.earnedUnlockMinutesToday = earnedUnlockMinutesToday
        self.lastCompletionTimestamp = lastCompletionTimestamp
        self.lastUnlockedPercent = lastUnlockedPercent
    }
}
