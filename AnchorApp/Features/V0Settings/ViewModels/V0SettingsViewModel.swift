import Foundation
import Shared

@MainActor
final class V0SettingsViewModel: ObservableObject {
    @Published var dailyState: V0DailyState

    private let storage = AppGroupStorage.shared

    init() {
        dailyState = storage.getV0DailyState()
    }

    func refresh() {
        dailyState = storage.getV0DailyState()
    }

    func updateResetTime(hour: Int, minute: Int) {
        var state = storage.getV0DailyState()
        state.dailyResetHour = hour
        state.dailyResetMinute = minute
        storage.setV0DailyState(state)
        dailyState = state
    }
}
