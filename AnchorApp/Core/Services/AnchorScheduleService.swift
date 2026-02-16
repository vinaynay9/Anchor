import Foundation
import Shared

final class AnchorScheduleService {
    static let shared = AnchorScheduleService()
    private let storage = AppGroupStorage.shared

    private init() {}

    var dailyAnchorTime: DailyAnchorTime {
        storage.getDailyAnchorTime() ?? DailyAnchorTime(hour: 9, minute: 0)
    }

    func updateDailyAnchorTime(_ time: DailyAnchorTime) {
        storage.setDailyAnchorTime(time)
    }
}
