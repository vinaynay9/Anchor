import Foundation

public struct IOULedgerEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public let contractId: UUID
    public let loserId: UUID
    public let creditorIds: [UUID]
    public let consequenceApplied: ConsequencePolicy?
    public let createdAt: Date
    public var resolvedAt: Date?
    
    public init(
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
