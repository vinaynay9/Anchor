import Foundation
import Shared

@MainActor
final class UnlockPolicyViewModel: ObservableObject {
    @Published var selectedMode: UnlockPolicyMode = .unlockAppsWhenAllTasksDone
    @Published var minutesPerGoal: Int = 15
    @Published var minutesPerPercent: Int = 15
    @Published var percentThreshold: Int = 50
    @Published var fixedTimeMinutes: Int = 15

    let minuteOptions = Array(stride(from: 5, through: 60, by: 5))
    let percentOptions = [25, 50, 75, 100]

    var isValid: Bool {
        switch selectedMode {
        case .unlockAppsWhenAllTasksDone:
            return true
        case .unlockFixedTimePerGoal:
            return minutesPerGoal > 0
        case .unlockFixedTimePerPercentCompleted:
            return minutesPerPercent > 0 && percentOptions.contains(percentThreshold)
        case .unlockFixedAppsPerGoalCompletedForFixedTime:
            return fixedTimeMinutes > 0
        }
    }

    func buildConfig() -> UnlockPolicyConfig {
        switch selectedMode {
        case .unlockAppsWhenAllTasksDone:
            return UnlockPolicyConfig(mode: .unlockAppsWhenAllTasksDone)
        case .unlockFixedTimePerGoal:
            return UnlockPolicyConfig(mode: .unlockFixedTimePerGoal, timeIntervalMinutes: minutesPerGoal)
        case .unlockFixedTimePerPercentCompleted:
            return UnlockPolicyConfig(mode: .unlockFixedTimePerPercentCompleted, timeIntervalMinutes: minutesPerPercent, percentStep: percentThreshold)
        case .unlockFixedAppsPerGoalCompletedForFixedTime:
            return UnlockPolicyConfig(mode: .unlockFixedAppsPerGoalCompletedForFixedTime, timeIntervalMinutes: fixedTimeMinutes)
        }
    }
}
