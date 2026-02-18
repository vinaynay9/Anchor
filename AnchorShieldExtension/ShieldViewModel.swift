import SwiftUI
import Shared

@MainActor
final class ShieldViewModel: ObservableObject {
    @Published var title: String = V0ShieldMessages.lockedTitle
    @Published var subtitle: String = V0ShieldMessages.lockedSubtitle
    @Published var progressText: String?

    private let storage = AppGroupStorage.shared

    init() {
        refresh()
    }

    func refresh() {
        let isLocked = storage.getV0IsLocked()
        let goals = storage.getV0Goals()
        let completed = storage.getV0DailyState().completedGoalIDsToday

        title = V0ShieldMessages.lockedTitle
        subtitle = V0ShieldMessages.lockedSubtitle

        if !goals.isEmpty {
            progressText = "Completed \(completed.count)/\(goals.count) today"
        } else {
            progressText = nil
        }
    }
}
