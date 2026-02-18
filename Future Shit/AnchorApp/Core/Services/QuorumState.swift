import Foundation

public struct QuorumState: Codable, Equatable {
    public var participantIds: [UUID]
    public var approvedIds: Set<UUID>
    public var deniedIds: Set<UUID>
    public var requiredApprovalCount: Int
    public var updatedAt: Date?
    
    public init(participantIds: [UUID], approvedIds: Set<UUID>, deniedIds: Set<UUID>, requiredApprovalCount: Int, updatedAt: Date? = nil) {
        self.participantIds = participantIds
        self.approvedIds = approvedIds
        self.deniedIds = deniedIds
        self.requiredApprovalCount = requiredApprovalCount
        self.updatedAt = updatedAt
    }
    
    public var hasReachedQuorum: Bool {
        return approvedIds.count >= requiredApprovalCount
    }
}
