import Foundation

struct LockSession: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let status: SessionStatus
    let startTime: Date
    let endTime: Date?
    let appsBlocked: [String] // Bundle identifiers
    let accountabilityPartnerId: UUID?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case startTime = "start_time"
        case endTime = "end_time"
        case appsBlocked = "apps_blocked"
        case accountabilityPartnerId = "accountability_partner_id"
        case createdAt = "created_at"
    }
}

enum SessionStatus: String, Codable, Hashable {
    case active
    case completed
    case cancelled
}

// MARK: - API DTOs
struct LockSessionDTO: Codable {
    let id: String
    let userId: String
    let status: String
    let startTime: String
    let endTime: String?
    let appsBlocked: [String]
    let accountabilityPartnerId: String?
    let createdAt: String
    
    func toLockSession() -> LockSession? {
        let formatter = ISO8601DateFormatter()
        guard let uuid = UUID(uuidString: id),
              let userIdUUID = UUID(uuidString: userId),
              let statusEnum = SessionStatus(rawValue: status),
              let startTimeDate = formatter.date(from: startTime),
              let createdAtDate = formatter.date(from: createdAt) else {
            return nil
        }
        
        let endTimeDate = endTime.flatMap { formatter.date(from: $0) }
        let accountabilityPartnerUUID = accountabilityPartnerId.flatMap { UUID(uuidString: $0) }
        
        return LockSession(
            id: uuid,
            userId: userIdUUID,
            status: statusEnum,
            startTime: startTimeDate,
            endTime: endTimeDate,
            appsBlocked: appsBlocked,
            accountabilityPartnerId: accountabilityPartnerUUID,
            createdAt: createdAtDate
        )
    }
}

