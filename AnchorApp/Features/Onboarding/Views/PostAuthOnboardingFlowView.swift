import SwiftUI
import Shared

// MARK: - Post-Auth Onboarding Flow
// Order: Goals → Reward Rules → Lock Schedule → App Selection

struct PostAuthOnboardingFlowView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path: [Shared.OnboardingStep] = []
    @State private var state = Shared.OnboardingState()

    @StateObject private var goalViewModel        = GoalSetupViewModel()
    @StateObject private var policyViewModel      = UnlockPolicyViewModel()
    @StateObject private var scheduleViewModel    = LockScheduleViewModel()
    @StateObject private var appSelectionViewModel = OnboardingAppSelectionViewModel()

    let onComplete: () -> Void

    var body: some View {
        NavigationStack(path: $path) {
            // ── Root: Goal Setup ─────────────────────────────────────────
            GoalSetupView(viewModel: goalViewModel, onNext: saveGoalsAndAdvance)
                .navigationDestination(for: Shared.OnboardingStep.self) { step in
                    switch step {

                    case .policy:
                        UnlockPolicyView(viewModel: policyViewModel, onNext: savePolicyAndAdvance)

                    case .lockSchedule:
                        LockScheduleView(viewModel: scheduleViewModel, onNext: saveScheduleAndAdvance)

                    case .appSelection:
                        OnboardingAppSelectionView(viewModel: appSelectionViewModel, onFinish: completeOnboarding)

                    case .goals:
                        GoalSetupView(viewModel: goalViewModel, onNext: saveGoalsAndAdvance)

                    case .complete:
                        EmptyView()
                    }
                }
                .task { await restorePath() }
                .toolbarBackground(AppColors.brandBackgroundDark, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationBarBackButtonHidden(false)
        }
        .background(AppColors.brandBackgroundDark.ignoresSafeArea())
        .animation(AppMotion.animation(AppMotion.standard, reduceMotion: reduceMotion), value: path)
    }

    // MARK: - Path restoration (resume from saved step)

    private func restorePath() async {
        let loaded = await OnboardingService.shared.loadState()
        state = loaded

        switch loaded.step {
        case .goals:
            path = []
        case .policy:
            path = [.policy]
        case .lockSchedule:
            path = [.policy, .lockSchedule]
        case .appSelection:
            path = [.policy, .lockSchedule, .appSelection]
        case .complete:
            onComplete()
        }
    }

    // MARK: - Step transitions

    private func saveGoalsAndAdvance() {
        state.goals = goalViewModel.buildGoals()
        advance(to: .policy)
    }

    private func savePolicyAndAdvance(config: UnlockPolicyConfig) {
        state.unlockPolicy = config
        advance(to: .lockSchedule)
    }

    private func saveScheduleAndAdvance() {
        // Lock time is saved directly to AppGroupStorage by LockScheduleViewModel.save()
        // (called before this callback). Nothing else to persist in OnboardingState here.
        advance(to: .appSelection)
    }

    private func advance(to next: Shared.OnboardingStep) {
        state.step = next
        Task { await OnboardingService.shared.saveState(state) }

        switch next {
        case .policy:
            path = [.policy]
        case .lockSchedule:
            path = [.policy, .lockSchedule]
        case .appSelection:
            path = [.policy, .lockSchedule, .appSelection]
        default:
            break
        }
    }

    private func completeOnboarding() {
        state.isComplete = true
        state.step       = .complete
        Task {
            await OnboardingService.shared.saveState(state)
            await OnboardingService.shared.markComplete()
            await MainActor.run { onComplete() }
        }
    }
}
