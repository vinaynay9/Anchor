import Foundation

// MARK: - Lock Plan (Intent)
struct LockPlan: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: LockPlanType
    var mode: LockMode
    var unlockPolicy: UnlockPolicy
    var goalRequirement: GoalRequirement
    var autoRelockRule: AutoRelockRule?
    var consequencePolicy: ConsequencePolicy?
    let createdAt: Date
    var isEditable: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        type: LockPlanType,
        mode: LockMode = .individual,
        unlockPolicy: UnlockPolicy = .self,
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

enum LockPlanType: String, Codable, Hashable {
    case study
    case work
    case chill
    case custom
}

enum LockMode: String, Codable, Hashable {
    case individual
    case group
}

enum UnlockPolicy: String, Codable, Hashable {
    case selfUnlock = "self"
    case friendApproval
    case quorum
}

enum GoalRequirement: String, Codable, Hashable {
    case none
    case selfMarked
    case friendApproved
}

enum AutoRelockRuleKind: String, Codable, Hashable {
    case bedtime
    case schedule
}

struct AutoRelockRule: Codable, Hashable {
    let kind: AutoRelockRuleKind
    let bedtimeStart: TimeOfDay?
    let bedtimeEnd: TimeOfDay?
    let schedule: LockSessionSchedule?
    let requiresConfirmationToDisable: Bool
    
    init(
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

struct ConsequencePolicy: Codable, Hashable {
    var extraLockMinutes: Int?
    var forcedCategories: [AppCategory]?
    var lockPlanEditDisabled: Bool
    var lockPlanDeletionDisabled: Bool
    
    init(
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
    static func recommendedDefaults() -> [LockPlan] {
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
