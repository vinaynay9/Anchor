import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let email: String
    let username: String
    let displayName: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case displayName = "display_name"
        case createdAt = "created_at"
    }
}

// MARK: - API DTOs
struct UserDTO: Codable {
    let id: String
    let email: String
    let username: String
    let displayName: String?
    let createdAt: String
    
    func toUser() -> User? {
        guard let uuid = UUID(uuidString: id),
              let createdAtDate = ISO8601DateFormatter().date(from: createdAt) else {
            return nil
        }
        return User(
            id: uuid,
            email: email,
            username: username,
            displayName: displayName,
            createdAt: createdAtDate
        )
    }
}

