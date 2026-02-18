import Foundation

public enum SocialContractStatus: String, Codable, Hashable {
    case active
    case resolved
    case breached
    case voided
}

public struct SocialContract: Identifiable, Codable, Hashable {
    public let id: UUID
    public let sessionId: UUID?
    public let challengeId: UUID?
    public let participants: [UUID]
    public let terms: String
    public let consequences: ConsequencePolicy
    public var status: SocialContractStatus
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        sessionId: UUID? = nil,
        challengeId: UUID? = nil,
        participants: [UUID],
        terms: String,
        consequences: ConsequencePolicy,
        status: SocialContractStatus = .active,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.challengeId = challengeId
        self.participants = participants
        self.terms = terms
        self.consequences = consequences
        self.status = status
        self.createdAt = createdAt
    }
}
