import Foundation

public struct QuorumState: Codable, Hashable {
    public let participantIds: [UUID]
    public var approvedIds: Set<UUID>
    public var deniedIds: Set<UUID>
    public let requiredApprovalCount: Int
    public let updatedAt: Date

    public init(
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

    public var hasReachedQuorum: Bool {
        approvedIds.count >= requiredApprovalCount
    }
}
