import Foundation

enum ShieldStateReason: String, Codable, Hashable {
    case activeLock
    case waitingForQuorum
    case goalNotApproved
    case contractPenaltyActive
    case unlockApproved
    case free
}

struct QuorumState: Codable, Hashable {
    let participantIds: [UUID]
    var approvedIds: Set<UUID>
    var deniedIds: Set<UUID>
    let requiredApprovalCount: Int
    let updatedAt: Date
    
    init(
        participantIds: [UUID],
        approvedIds: Set<UUID> = [],
        deniedIds: Set<UUID> = [],
        requiredApprovalCount: Int,
        updatedAt: Date = Date()
    ) {
        self.participantIds = participantIds
        self.approvedIds = approvedIds
        self.deniedIds = deniedIds
        self.requiredApprovalCount = requiredApprovalCount
        self.updatedAt = updatedAt
    }
    
    var approvalCount: Int { approvedIds.count }
    var denialCount: Int { deniedIds.count }
    
    var hasReachedQuorum: Bool {
        approvalCount >= requiredApprovalCount
    }
}

struct ShieldState: Codable, Hashable {
    let reason: ShieldStateReason
    let sessionId: UUID?
    let planName: String?
    let planType: LockPlanType?
    let unlockPolicy: UnlockPolicy?
    let goalRequirement: GoalRequirement?
    let quorumState: QuorumState?
    let message: String?
    let updatedAt: Date
    
    init(
        reason: ShieldStateReason,
        sessionId: UUID? = nil,
        planName: String? = nil,
        planType: LockPlanType? = nil,
        unlockPolicy: UnlockPolicy? = nil,
        goalRequirement: GoalRequirement? = nil,
        quorumState: QuorumState? = nil,
        message: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.reason = reason
        self.sessionId = sessionId
        self.planName = planName
        self.planType = planType
        self.unlockPolicy = unlockPolicy
        self.goalRequirement = goalRequirement
        self.quorumState = quorumState
        self.message = message
        self.updatedAt = updatedAt
    }
}

extension ShieldState {
    var isBlocking: Bool {
        switch reason {
        case .activeLock, .waitingForQuorum, .goalNotApproved, .contractPenaltyActive:
            return true
        case .unlockApproved, .free:
            return false
        }
    }
}

