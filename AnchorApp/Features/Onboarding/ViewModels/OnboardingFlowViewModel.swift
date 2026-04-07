import SwiftUI

// MARK: - Onboarding Flow ViewModel
// Minimal persistence layer for the welcome pager.
// The previous splash/pager stage machine was removed when the welcome screen
// was merged into Page 1 of the new OnboardingPagerView.
@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @AppStorage("hasCompletedOnboarding") private(set) var hasCompletedOnboarding: Bool = false

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
