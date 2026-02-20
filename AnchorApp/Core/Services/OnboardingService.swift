import Foundation
import Shared

@MainActor
final class OnboardingService {
    static let shared = OnboardingService()
    private init() {}

    func loadState() async -> Shared.OnboardingState {
        if let saved = AppGroupStorage.shared.getOnboardingState() {
            return saved
        }
        let fresh = Shared.OnboardingState()
        AppGroupStorage.shared.setOnboardingState(fresh)
        return fresh
    }

    func saveState(_ state: Shared.OnboardingState) async {
        AppGroupStorage.shared.setOnboardingState(state)
    }

    func markComplete() async {
        var state = await loadState()
        state.isComplete = true
        state.step = .complete
        AppGroupStorage.shared.setOnboardingState(state)
    }
}
