import Foundation

public enum ShieldStateReason: String, Codable, Hashable {
    case activeLock
    case waitingForQuorum
    case goalNotApproved
    case contractPenaltyActive
    case unlockApproved
    case free
}

public struct ShieldState: Codable {
    public let reason: ShieldStateReason
    public let sessionId: UUID?
    public let planName: String?
    public let planType: LockPlanType?
    public let unlockPolicy: UnlockPolicy?
    public let goalRequirement: GoalRequirement?
    public let quorumState: QuorumState?
    public let message: String?
    public let updatedAt: Date
    
    public init(
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
    public var isBlocking: Bool {
        switch reason {
        case .activeLock, .waitingForQuorum, .goalNotApproved, .contractPenaltyActive:
            return true
        case .unlockApproved, .free:
            return false
        }
    }
}
