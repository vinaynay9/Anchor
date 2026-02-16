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
    
    public init(id: UUID, friendId: String, type: FriendActivityType, timestamp: Date, metadata: [String: String]? = nil) {
        self.id = id
        self.friendId = friendId
        self.type = type
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

public struct FriendActivityEventDTO: Codable {
    public let id: String
    public let friendId: String
    public let type: String
    public let timestamp: String
    public let metadata: [String: String]?
    
    public init(id: String, friendId: String, type: String, timestamp: String, metadata: [String: String]? = nil) {
        self.id = id
        self.friendId = friendId
        self.type = type
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    public func toFriendActivityEvent() -> FriendActivityEvent? {
        let formatter = ISO8601DateFormatter()
        guard let uuid = UUID(uuidString: id),
              let activityType = FriendActivityType(rawValue: type),
              let date = formatter.date(from: timestamp) else {
            return nil
        }
        return FriendActivityEvent(id: uuid, friendId: friendId, type: activityType, timestamp: date, metadata: metadata)
    }
}
