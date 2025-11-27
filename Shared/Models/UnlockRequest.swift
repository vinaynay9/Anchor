import Foundation

struct UnlockRequest: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionId: UUID
    let requesterId: UUID
    let partnerId: UUID
    let status: UnlockRequestStatus
    let message: String?
    let createdAt: Date
    let resolvedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case requesterId = "requester_id"
        case partnerId = "partner_id"
        case status
        case message
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
    }
}

enum UnlockRequestStatus: String, Codable, Hashable {
    case pending
    case approved
    case denied
}

// MARK: - API DTOs
struct UnlockRequestDTO: Codable {
    let id: String
    let sessionId: String
    let requesterId: String
    let partnerId: String
    let status: String
    let message: String?
    let createdAt: String
    let resolvedAt: String?
    
    func toUnlockRequest() -> UnlockRequest? {
        let formatter = ISO8601DateFormatter()
        guard let uuid = UUID(uuidString: id),
              let sessionIdUUID = UUID(uuidString: sessionId),
              let requesterIdUUID = UUID(uuidString: requesterId),
              let partnerIdUUID = UUID(uuidString: partnerId),
              let statusEnum = UnlockRequestStatus(rawValue: status),
              let createdAtDate = formatter.date(from: createdAt) else {
            return nil
        }
        
        let resolvedAtDate = resolvedAt.flatMap { formatter.date(from: $0) }
        
        return UnlockRequest(
            id: uuid,
            sessionId: sessionIdUUID,
            requesterId: requesterIdUUID,
            partnerId: partnerIdUUID,
            status: statusEnum,
            message: message,
            createdAt: createdAtDate,
            resolvedAt: resolvedAtDate
        )
    }
}

