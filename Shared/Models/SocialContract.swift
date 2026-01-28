import Foundation

enum SocialContractStatus: String, Codable, Hashable {
    case active
    case resolved
    case breached
    case voided
}

struct SocialContract: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionId: UUID?
    let challengeId: UUID?
    let participants: [UUID]
    let terms: String
    let consequences: ConsequencePolicy
    var status: SocialContractStatus
    let createdAt: Date
    
    init(
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

