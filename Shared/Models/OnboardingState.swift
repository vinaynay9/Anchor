import Foundation

public enum OnboardingStep: String, Codable, Hashable, CaseIterable {
    case goals
    case policy
    case appSelection
    case complete
}

public struct OnboardingState: Codable, Hashable {
    public var step: OnboardingStep
    public var goals: [Goal]
    public var unlockPolicy: UnlockPolicyConfig?
    public var blockedSelectionData: Data?
    public var unlockedPerGoalSelectionData: Data?
    public var isComplete: Bool

    public init(
        step: OnboardingStep = .goals,
        goals: [Goal] = [],
        unlockPolicy: UnlockPolicyConfig? = nil,
        blockedSelectionData: Data? = nil,
        unlockedPerGoalSelectionData: Data? = nil,
        isComplete: Bool = false
    ) {
        self.step = step
        self.goals = goals
        self.unlockPolicy = unlockPolicy
        self.blockedSelectionData = blockedSelectionData
        self.unlockedPerGoalSelectionData = unlockedPerGoalSelectionData
        self.isComplete = isComplete
    }
}
