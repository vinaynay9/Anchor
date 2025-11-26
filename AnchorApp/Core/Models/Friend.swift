import Foundation

struct Friend: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let friendId: UUID
    let friend: User? // Populated when fetching with joins
    let status: FriendshipStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case friend
        case status
        case createdAt = "created_at"
    }
}

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case blocked
}

// MARK: - API DTOs
struct FriendDTO: Codable {
    let id: String
    let userId: String
    let friendId: String
    let friend: UserDTO?
    let status: String
    let createdAt: String
    
    func toFriend() -> Friend? {
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

