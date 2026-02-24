import Foundation
import FamilyControls
import Shared

@MainActor
final class OnboardingAppSelectionViewModel: ObservableObject {
    @Published var blockedSelection = FamilyActivitySelection()
    @Published var unlockedSelection = FamilyActivitySelection()
    @Published var showUnlockedAppsSection = false
    @Published var selectedPresets: Set<String> = []

    private let onboardingService = OnboardingService.shared
    private let activitySelectionService = ActivitySelectionService.shared
    private let storage = AppGroupStorage.shared

    var hasBlockedSelection: Bool {
        !blockedSelection.applicationTokens.isEmpty || !blockedSelection.categoryTokens.isEmpty
    }

    func loadState() async {
        let state = await onboardingService.loadState()
        showUnlockedAppsSection = state.unlockPolicy?.mode == .unlockFixedAppsPerGoalCompletedForFixedTime
    }

    func persistSelections() async {
        var state = await onboardingService.loadState()
        state.blockedSelectionData = encode(selection: blockedSelection)
        state.unlockedPerGoalSelectionData = encode(selection: unlockedSelection)
        state.step = .complete
        await onboardingService.saveState(state)

        _ = activitySelectionService.saveSelectionSafe(blockedSelection)
        storage.saveUnlockedFamilyActivitySelection(unlockedSelection)
    }

    func markComplete() async {
        await onboardingService.markComplete()
    }

    private func encode(selection: FamilyActivitySelection) -> Data? {
        try? JSONEncoder().encode(selection)
    }
}
