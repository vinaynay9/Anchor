import Foundation
import DeviceActivity
import Shared

final class DailyAnchorService {
    static let shared = DailyAnchorService()

    private let storage = AppGroupStorage.shared
    private let scheduleService = AnchorScheduleService.shared
    private let deviceActivityService = DeviceActivityService.shared
    private let screenTimeService: ScreenTimeServiceProtocol

    private init(screenTimeService: ScreenTimeServiceProtocol = ScreenTimeService.shared) {
        self.screenTimeService = screenTimeService
    }

    func registerScheduleIfNeeded() {
        guard screenTimeService.isAuthorized() else { return }
        let time = scheduleService.dailyAnchorTime
        do {
            try deviceActivityService.scheduleDailyAnchor(startTime: time)
        } catch {
            LoggerService.shared.logError("Failed to schedule daily anchor", error: error, category: "DeviceActivity")
        }
    }

    func applyIfNeeded() async {
        let today = localDayString(for: Date())
        let lastApplied = storage.getLastDailyAnchorAppliedDate()

        let now = Date()
        let lockTime = scheduleService.dailyAnchorTime
        if shouldApplyAnchor(now: now, lockTime: lockTime, lastAppliedDate: lastApplied, today: today) {
            await screenTimeService.applyDailyAnchor()
            storage.setLastDailyAnchorAppliedDate(today)
            storage.setShieldState(ShieldState(reason: .activeLock))
        }

        if let temporaryUntil = storage.getTemporaryUnlockUntil(), Date() >= temporaryUntil {
            storage.setTemporaryUnlockUntil(nil)
            await screenTimeService.applyDailyAnchor()
            storage.setShieldState(ShieldState(reason: .activeLock))
        }
    }

    func updateLockStartTime(_ time: DailyAnchorTime) {
        scheduleService.updateDailyAnchorTime(time)
        registerScheduleIfNeeded()
    }

    private func shouldApplyAnchor(now: Date, lockTime: DailyAnchorTime, lastAppliedDate: String?, today: String) -> Bool {
        if lastAppliedDate == today { return false }
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = lockTime.hour
        components.minute = lockTime.minute
        components.second = 0
        guard let lockDate = calendar.date(from: components) else { return false }
        return now >= lockDate
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
