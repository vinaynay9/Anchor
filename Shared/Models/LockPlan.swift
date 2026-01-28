import Foundation

// MARK: - Lock Plan (Intent)
// TEST TEST TEST
public struct LockPlan: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var type: LockPlanType
    public var mode: LockMode
    public var unlockPolicy: UnlockPolicy
    public var goalRequirement: GoalRequirement
    public var autoRelockRule: AutoRelockRule?
    public var consequencePolicy: ConsequencePolicy?
    public let createdAt: Date
    public var isEditable: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: LockPlanType,
        mode: LockMode = .individual,
        unlockPolicy: UnlockPolicy = .selfUnlock,
        goalRequirement: GoalRequirement = .none,
        autoRelockRule: AutoRelockRule? = nil,
        consequencePolicy: ConsequencePolicy? = nil,
        createdAt: Date = Date(),
        isEditable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.mode = mode
        self.unlockPolicy = unlockPolicy
        self.goalRequirement = goalRequirement
        self.autoRelockRule = autoRelockRule
        self.consequencePolicy = consequencePolicy
        self.createdAt = createdAt
        self.isEditable = isEditable
    }
}

public enum LockPlanType: String, Codable, Hashable {
    case study
    case work
    case chill
    case custom
}

public enum LockMode: String, Codable, Hashable {
    case individual
    case group
}

public enum UnlockPolicy: String, Codable, Hashable {
    case selfUnlock = "self"
    case friendApproval
    case quorum
}

public enum GoalRequirement: String, Codable, Hashable {
    case none
    case selfMarked
    case friendApproved
}

public enum AutoRelockRuleKind: String, Codable, Hashable {
    case bedtime
    case schedule
}

public struct AutoRelockRule: Codable, Hashable {
    public let kind: AutoRelockRuleKind
    public let bedtimeStart: TimeOfDay?
    public let bedtimeEnd: TimeOfDay?
    public let schedule: LockSessionSchedule?
    public let requiresConfirmationToDisable: Bool
    
    public init(
        kind: AutoRelockRuleKind,
        bedtimeStart: TimeOfDay? = nil,
        bedtimeEnd: TimeOfDay? = nil,
        schedule: LockSessionSchedule? = nil,
        requiresConfirmationToDisable: Bool = true
    ) {
        self.kind = kind
        self.bedtimeStart = bedtimeStart
        self.bedtimeEnd = bedtimeEnd
        self.schedule = schedule
        self.requiresConfirmationToDisable = requiresConfirmationToDisable
    }
}

public struct ConsequencePolicy: Codable, Hashable {
    public var extraLockMinutes: Int?
    public var forcedCategories: [AppCategory]?
    public var lockPlanEditDisabled: Bool
    public var lockPlanDeletionDisabled: Bool
    
    public init(
        extraLockMinutes: Int? = nil,
        forcedCategories: [AppCategory]? = nil,
        lockPlanEditDisabled: Bool = false,
        lockPlanDeletionDisabled: Bool = false
    ) {
        self.extraLockMinutes = extraLockMinutes
        self.forcedCategories = forcedCategories
        self.lockPlanEditDisabled = lockPlanEditDisabled
        self.lockPlanDeletionDisabled = lockPlanDeletionDisabled
    }
}

// MARK: - Recommended Defaults (Opinionated, not separate code paths)
extension LockPlan {
    public static func recommendedDefaults() -> [LockPlan] {
        return [
            LockPlan(
                name: "Study Lock",
                type: .study,
                mode: .individual,
                unlockPolicy: .friendApproval,
                goalRequirement: .selfMarked,
                autoRelockRule: AutoRelockRule(kind: .bedtime, requiresConfirmationToDisable: true)
            ),
            LockPlan(
                name: "Work Lock",
                type: .work,
                mode: .individual,
                unlockPolicy: .selfUnlock,
                goalRequirement: .none,
                autoRelockRule: AutoRelockRule(kind: .schedule, requiresConfirmationToDisable: true)
            ),
            LockPlan(
                name: "Chill Lock",
                type: .chill,
                mode: .individual,
                unlockPolicy: .selfUnlock,
                goalRequirement: .none,
                autoRelockRule: nil
            )
        ]
    }
}
