import Foundation

public struct V0UnlockConfig: Codable, Hashable {
    public var mode: V0UnlockMode
    public var timeIntervalMinutes: Int
    public var percentStep: Int

    public init(
        mode: V0UnlockMode = .unlockAppsWhenAllTasksDone,
        timeIntervalMinutes: Int = 15,
        percentStep: Int = 25
    ) {
        self.mode = mode
        self.timeIntervalMinutes = timeIntervalMinutes
        self.percentStep = percentStep
    }
}
