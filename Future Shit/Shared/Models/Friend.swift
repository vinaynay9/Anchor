import Foundation

public struct Friend: Identifiable, Codable, Hashable {
    public let id: UUID
    public let userId: UUID
    public let friendId: UUID
    public let friend: User? // Populated when fetching with joins
    public let status: FriendshipStatus
    public let createdAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case friend
        case status
        case createdAt = "created_at"
    }

    public var displayName: String {
        if let displayName = friend?.displayName, !displayName.isEmpty {
            return displayName
        }
        return friend?.username ?? ""
    }
}

public enum FriendshipStatus: String, Codable, Hashable {
    case pending
    case accepted
    case blocked
}

// MARK: - API DTOs
public struct FriendDTO: Codable {
    public let id: String
    public let userId: String
    public let friendId: String
    public let friend: UserDTO?
    public let status: String
    public let createdAt: String
    
    public enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case friend
        case status
        case createdAt = "created_at"
    }
    
    public func toFriend() -> Friend? {
        guard let uuid = UUID(uuidString: id),
              let userIdUUID = UUID(uuidString: userId),
              let friendIdUUID = UUID(uuidString: friendId),
              let statusEnum = FriendshipStatus(rawValue: status),
              let createdAtDate = ISO8601DateFormatter().date(from: createdAt) else {
            return nil
        }
        return Friend(
            id: uuid,
            userId: userIdUUID,
            friendId: friendIdUUID,
            friend: friend?.toUser(),
            status: statusEnum,
            createdAt: createdAtDate
        )
    }
}
