import SwiftUI

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    enum Stage {
        case splash
        case pager
    }

    @AppStorage("hasSeenOnboarding") private(set) var hasSeenOnboarding: Bool = false
    @AppStorage("hasCompletedOnboarding") private(set) var hasCompletedOnboarding: Bool = false

    @Published var stage: Stage = .splash

    init() {
        stage = hasSeenOnboarding ? .pager : .splash
    }

    func markSeen() {
        hasSeenOnboarding = true
        stage = .pager
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
