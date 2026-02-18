import Foundation
import Shared

final class V0DailyResetService {
    static let shared = V0DailyResetService()

    private let storage = AppGroupStorage.shared
    private let unlockPolicyService = V0UnlockPolicyService.shared

    private init() {}

    func runIfNeeded(now: Date = Date()) {
        var state = storage.getV0DailyState()
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = state.dailyResetHour
        components.minute = state.dailyResetMinute
        components.second = 0

        guard let todayReset = calendar.date(from: components) else { return }

        let resetBoundary: Date
        if now >= todayReset {
            resetBoundary = todayReset
        } else {
            resetBoundary = calendar.date(byAdding: .day, value: -1, to: todayReset) ?? todayReset
        }

        if state.lastResetLocalDate < resetBoundary {
            state.completedGoalIDsToday.removeAll()
            state.availableUnlockMinutesToday = 0
            state.lastUnlockMilestonePercent = 0
            state.lastResetLocalDate = resetBoundary
            storage.setV0DailyState(state)
            unlockPolicyService.applyBaselineLocks()
        }
    }
}
