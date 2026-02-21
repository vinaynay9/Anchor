import SwiftUI
import Shared

struct PostAuthOnboardingFlowView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path: [Shared.OnboardingStep] = []
    @State private var state = Shared.OnboardingState()
    @StateObject private var goalViewModel = GoalSetupViewModel()
    @StateObject private var policyViewModel = UnlockPolicyViewModel()
    @StateObject private var appSelectionViewModel = OnboardingAppSelectionViewModel()

    let onComplete: () -> Void

    var body: some View {
        NavigationStack(path: $path) {
            GoalSetupView(viewModel: goalViewModel, onNext: {
                saveGoalsAndAdvance()
            })
            .navigationDestination(for: Shared.OnboardingStep.self) { step in
                switch step {
                case .policy:
                    UnlockPolicyView(viewModel: policyViewModel, onNext: { config in
                        savePolicyAndAdvance(config: config)
                    })
                case .appSelection:
                    OnboardingAppSelectionView(viewModel: appSelectionViewModel, onFinish: {
                        completeOnboarding()
                    })
                case .goals:
                    GoalSetupView(viewModel: goalViewModel, onNext: {
                        saveGoalsAndAdvance()
                    })
                case .complete:
                    EmptyView()
                }
            }
            .task {
                await restorePath()
            }
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .background(AppColors.background.ignoresSafeArea())
        .animation(AppMotion.animation(AppMotion.standard, reduceMotion: reduceMotion), value: path)
    }

    private func restorePath() async {
        let loaded = await OnboardingService.shared.loadState()
        state = loaded

        switch loaded.step {
        case .goals:
            path = []
        case .policy:
            path = [.policy]
        case .appSelection:
            path = [.policy, .appSelection]
        case .complete:
            onComplete()
        }
    }

    private func advance(to next: Shared.OnboardingStep) {
        state.step = next
        Task {
            await OnboardingService.shared.saveState(state)
        }
        if next == .policy {
            path = [.policy]
        } else if next == .appSelection {
            path = [.policy, .appSelection]
        }
    }

    private func completeOnboarding() {
        state.isComplete = true
        state.step = .complete
        Task {
            await OnboardingService.shared.saveState(state)
            await OnboardingService.shared.markComplete()
            await MainActor.run {
                onComplete()
            }
        }
    }

    private func saveGoalsAndAdvance() {
        state.goals = goalViewModel.buildGoals()
        advance(to: .policy)
    }

    private func savePolicyAndAdvance(config: UnlockPolicyConfig) {
        state.unlockPolicy = config
        advance(to: .appSelection)
    }
}
