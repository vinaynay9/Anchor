import Foundation
import Combine
import Shared

@MainActor
final class V0HomeViewModel: ObservableObject {
    @Published var goals: [V0Goal] = []
    @Published var completedGoalIDs: Set<UUID> = []
    @Published var isLocked: Bool = true

    private let storage = AppGroupStorage.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        reload()
        storage.updatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    func reload() {
        goals = storage.getV0Goals()
        completedGoalIDs = storage.getV0DailyState().completedGoalIDsToday
        isLocked = storage.getV0IsLocked()
    }

    func isGoalCompleted(_ goal: V0Goal) -> Bool {
        completedGoalIDs.contains(goal.id)
    }
}
