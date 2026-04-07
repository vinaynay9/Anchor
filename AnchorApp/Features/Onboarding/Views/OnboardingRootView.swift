import SwiftUI

// MARK: - Onboarding Root
// Displays the full-screen welcome pager.  The old "splash → pager" stage
// machine is no longer needed because Page 1 of the new pager is the welcome
// screen; the FlowViewModel is kept only to persist `hasCompletedOnboarding`.
struct OnboardingRootView: View {
    @StateObject private var viewModel = OnboardingFlowViewModel()

    let onComplete: () -> Void

    var body: some View {
        OnboardingPagerView(onLogin: {
            viewModel.completeOnboarding()
            onComplete()
        })
        .ignoresSafeArea()
    }
}
