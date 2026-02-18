import Foundation
import FamilyControls
import Shared

final class V0UnlockPolicyService {
    static let shared = V0UnlockPolicyService()

    private let storage = AppGroupStorage.shared
    private let screenTimeService: ScreenTimeServiceProtocol
    private var unlockTimer: Timer?

    private init(screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared) {
        self.screenTimeService = screenTimeService
    }

    func applyBaselineLocks() {
        screenTimeService.applyBlockingFromStorage()
    }

    func handleGoalCompletion(goalId: UUID) {
        var state = storage.getV0DailyState()
        state.completedGoalIDsToday.insert(goalId)
        storage.setV0DailyState(state)

        let goals = storage.getV0Goals()
        guard let config = storage.getV0UnlockConfig() else { return }

        switch config.mode {
        case .unlockAppsWhenAllTasksDone:
            if state.completedGoalIDsToday.count >= goals.count, !goals.isEmpty {
                screenTimeService.clearBlocking()
            }

        case .unlockFixedTimePerGoal:
            grantTemporaryUnlock(minutes: config.timeIntervalMinutes)

        case .unlockFixedTimePerPercentCompleted:
            guard !goals.isEmpty else { return }
            let percentCompleted = Int((Double(state.completedGoalIDsToday.count) / Double(goals.count)) * 100.0)
            let step = max(1, config.percentStep)
            let milestone = (percentCompleted / step) * step
            if milestone > state.lastUnlockMilestonePercent {
                state.lastUnlockMilestonePercent = milestone
                storage.setV0DailyState(state)
                grantTemporaryUnlock(minutes: config.timeIntervalMinutes)
            }

        case .unlockFixedAppsPerGoalCompletedForFixedTime:
            grantTemporaryUnlock(minutes: config.timeIntervalMinutes)
        }
    }

    private func grantTemporaryUnlock(minutes: Int) {
        unlockTimer?.invalidate()

        let selection = storage.getV0AppSelection()
        let allowedTokens = storage.decodeApplicationTokens(selection.perGoalUnlockedApplications)

        screenTimeService.applyTemporaryAllowance(allowedApplications: allowedTokens)

        var state = storage.getV0DailyState()
        state.availableUnlockMinutesToday = minutes
        storage.setV0DailyState(state)

        unlockTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            self?.screenTimeService.applyBlockingFromStorage()
            var state = self?.storage.getV0DailyState() ?? V0DailyState()
            state.availableUnlockMinutesToday = 0
            self?.storage.setV0DailyState(state)
        }
    }
}
