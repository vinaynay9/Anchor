import Foundation

@MainActor
final class V0OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case auth
        case goals
        case unlock
        case presets
        case selection
    }

    @Published var step: Step = .auth

    func goNext() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func goBack() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        step = prev
    }
}
