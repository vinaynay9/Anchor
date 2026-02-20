import Foundation
import FamilyControls
import Shared

@MainActor
final class DailyGoalService {
    static let shared = DailyGoalService()

    private let storage = AppGroupStorage.shared
    private let onboardingService = OnboardingService.shared
    private let screenTimeService: ScreenTimeServiceProtocol

    private init(screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared) {
        self.screenTimeService = screenTimeService
    }

    func loadGoals() async -> [Shared.Goal] {
        let state = await onboardingService.loadState()
        return state.goals
    }

    func loadProgress() -> DailyGoalProgress {
        let today = localDayString(for: Date())
        if let existing = storage.getDailyGoalProgress(), existing.date == today {
            return existing
        }
        let fresh = DailyGoalProgress(date: today)
        storage.setDailyGoalProgress(fresh)
        return fresh
    }

    func isAnchored() -> Bool {
        storage.getShieldState()?.isBlocking ?? false
    }

    func markGoalCompleted(goalId: UUID) async -> DailyGoalProgress {
        var progress = loadProgress()
        if !progress.completedGoalIds.contains(goalId) {
            progress.completedGoalIds.append(goalId)
        }
        progress.lastCompletionTimestamp = Date()

        let state = await onboardingService.loadState()
        let goals = state.goals
        let policy = state.unlockPolicy

        if let policy = policy {
            await applyUnlockPolicy(policy, goals: goals, progress: &progress)
        }

        storage.setDailyGoalProgress(progress)
        return progress
    }

    private func applyUnlockPolicy(_ policy: UnlockPolicyConfig, goals: [Shared.Goal], progress: inout DailyGoalProgress) async {
        let total = max(goals.count, 1)
        let completed = progress.completedGoalIds.count
        let completionPercent = Int((Double(completed) / Double(total)) * 100.0)

        switch policy.mode {
        case .unlockAppsWhenAllTasksDone:
            if completed >= total {
                await screenTimeService.stopBlocking()
                storage.setShieldState(ShieldState(reason: .free))
            }

        case .unlockFixedTimePerGoal:
            let minutes = policy.timeIntervalMinutes ?? 0
            guard minutes > 0 else { return }
            progress.earnedUnlockMinutesToday += minutes
            await screenTimeService.emergencyUnanchor(duration: TimeInterval(minutes * 60))

        case .unlockFixedTimePerPercentCompleted:
            let minutes = policy.timeIntervalMinutes ?? 0
            let step = policy.percentStep ?? 25
            guard minutes > 0, step > 0 else { return }
            let nextThreshold = progress.lastUnlockedPercent + step
            if completionPercent >= nextThreshold {
                progress.lastUnlockedPercent = min(100, nextThreshold)
                progress.earnedUnlockMinutesToday += minutes
                await screenTimeService.emergencyUnanchor(duration: TimeInterval(minutes * 60))
            }

        case .unlockFixedAppsPerGoalCompletedForFixedTime:
            let minutes = policy.timeIntervalMinutes ?? 0
            guard minutes > 0 else { return }

            let blocked = storage.loadFamilyActivitySelection(forKey: .familyActivitySelection)
            let unlocked = storage.loadUnlockedFamilyActivitySelection()
            let blockedTokens = Set(blocked?.applicationTokens ?? [])
            let unlockedTokens = Set(unlocked?.applicationTokens ?? [])

            await screenTimeService.applyTemporaryUnlock(
                blockedTokens: blockedTokens,
                allowedTokens: unlockedTokens,
                duration: TimeInterval(minutes * 60)
            )
        }
    }

    private func localDayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
