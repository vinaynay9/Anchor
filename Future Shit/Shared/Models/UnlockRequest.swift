import Foundation

public struct UnlockRequest: Identifiable, Codable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let requesterId: UUID
    public let partnerId: UUID
    public let status: UnlockRequestStatus
    public let message: String?
    public let appBundleId: String?
    public let createdAt: Date
    public let resolvedAt: Date?

    public init(
        id: UUID,
        sessionId: UUID,
        requesterId: UUID,
        partnerId: UUID,
        status: UnlockRequestStatus,
        message: String?,
        appBundleId: String?,
        createdAt: Date,
        resolvedAt: Date?
    ) {
        self.id = id
        self.sessionId = sessionId
        self.requesterId = requesterId
        self.partnerId = partnerId
        self.status = status
        self.message = message
        self.appBundleId = appBundleId
        self.createdAt = createdAt
        self.resolvedAt = resolvedAt
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case requesterId = "requester_id"
        case partnerId = "partner_id"
        case status
        case message
        case appBundleId = "app_bundle_id"
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
    }
}

public enum UnlockRequestStatus: String, Codable, Hashable {
    case pending
    case approved
    case denied
    case queued  // Offline: queued for retry when network is restored
}

// MARK: - API DTOs
public struct UnlockRequestDTO: Codable {
    public let id: String
    public let sessionId: String
    public let requesterId: String
    public let partnerId: String
    public let status: String
    public let message: String?
    public let appBundleId: String?
    public let createdAt: String
    public let resolvedAt: String?
    
    public func toUnlockRequest() -> UnlockRequest? {
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
            appBundleId: appBundleId,
            createdAt: createdAtDate,
            resolvedAt: resolvedAtDate
        )
    }
}
