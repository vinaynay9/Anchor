import Foundation

public enum FriendActivityType: String, Codable {
    case proofSubmitted
    case unlockRequested
    case unlockApproved
    case sessionStarted
    case sessionCompleted
}

public struct FriendActivityEvent: Identifiable, Codable {
    public let id: UUID
    public let friendId: String
    public let type: FriendActivityType
    public let timestamp: Date
    public let metadata: [String: String]?
    
    public enum CodingKeys: String, CodingKey {
        case id
        case friendId = "friend_id"
        case type
        case timestamp
        case metadata
    }
}

// MARK: - API DTOs
public struct FriendActivityEventDTO: Codable {
    public let id: String
    public let friendId: String
    public let type: String
    public let timestamp: String
    public let metadata: [String: String]?
    
    public enum CodingKeys: String, CodingKey {
        case id
        case friendId = "friend_id"
        case type
        case timestamp
        case metadata
    }
    
    public func toFriendActivityEvent() -> FriendActivityEvent? {
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
