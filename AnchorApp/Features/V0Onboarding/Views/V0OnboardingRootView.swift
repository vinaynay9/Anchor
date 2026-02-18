import SwiftUI

struct V0OnboardingRootView: View {
    @StateObject private var viewModel = V0OnboardingViewModel()

    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                contentView
            }
            .navigationTitle("Setup")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.step != .auth {
                        Button("Back") {
                            viewModel.goBack()
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .applyV0Theme()
            .onAppear {
                Task {
                    if let _ = try? await AuthService.shared.currentUser() {
                        if viewModel.step == .auth {
                            viewModel.step = .goals
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.step {
        case .auth:
            V0AuthEntryView {
                viewModel.goNext()
            }
        case .goals:
            V0GoalSetupView {
                viewModel.goNext()
            }
        case .unlock:
            V0UnlockRuleSetupView {
                viewModel.goNext()
            }
        case .presets:
            V0AppPresetSelectionView {
                viewModel.goNext()
            }
        case .selection:
            V0AppSelectionView {
                onComplete()
            }
        }
    }
}
