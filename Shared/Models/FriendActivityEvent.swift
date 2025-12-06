import Foundation

enum FriendActivityType: String, Codable {
    case proofSubmitted
    case unlockRequested
    case unlockApproved
    case sessionStarted
    case sessionCompleted
}

struct FriendActivityEvent: Identifiable, Codable {
    let id: UUID
    let friendId: String
    let type: FriendActivityType
    let timestamp: Date
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case friendId = "friend_id"
        case type
        case timestamp
        case metadata
    }
}

// MARK: - API DTOs
struct FriendActivityEventDTO: Codable {
    let id: String
    let friendId: String
    let type: String
    let timestamp: String
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case friendId = "friend_id"
        case type
        case timestamp
        case metadata
    }
    
    func toFriendActivityEvent() -> FriendActivityEvent? {
        let formatter = ISO8601DateFormatter()
        guard let uuid = UUID(uuidString: id),
              let activityType = FriendActivityType(rawValue: type),
              let timestampDate = formatter.date(from: timestamp) else {
            return nil
        }
        
        return FriendActivityEvent(
            id: uuid,
            friendId: friendId,
            type: activityType,
            timestamp: timestampDate,
            metadata: metadata
        )
    }
}

