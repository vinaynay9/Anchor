import Foundation

struct IOULedgerEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let contractId: UUID
    let loserId: UUID
    let creditorIds: [UUID]
    let consequenceApplied: ConsequencePolicy?
    let createdAt: Date
    var resolvedAt: Date?
    
    init(
        id: UUID = UUID(),
        contractId: UUID,
        loserId: UUID,
        creditorIds: [UUID],
        consequenceApplied: ConsequencePolicy? = nil,
        createdAt: Date = Date(),
        resolvedAt: Date? = nil
    ) {
        self.id = id
        self.contractId = contractId
        self.loserId = loserId
        self.creditorIds = creditorIds
        self.consequenceApplied = consequenceApplied
        self.createdAt = createdAt
        self.resolvedAt = resolvedAt
    }
}

