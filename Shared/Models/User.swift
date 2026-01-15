import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let email: String
    let username: String
    let displayName: String?
    let createdAt: Date
    let role: UserRole
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case displayName = "display_name"
        case createdAt = "created_at"
        case role
    }
    
    init(id: UUID, email: String, username: String, displayName: String?, createdAt: Date, role: UserRole = .user) {
        self.id = id
        self.email = email
        self.username = username
        self.displayName = displayName
        self.createdAt = createdAt
        self.role = role
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let email = try container.decode(String.self, forKey: .email)
        let username = try container.decode(String.self, forKey: .username)
        let displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let role = (try? container.decode(UserRole.self, forKey: .role)) ?? .user
        self.init(id: id, email: email, username: username, displayName: displayName, createdAt: createdAt, role: role)
    }
}

// MARK: - API DTOs
struct UserDTO: Codable {
    let id: String
    let email: String
    let username: String
    let displayName: String?
    let createdAt: String
    let role: UserRole?
    
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
            createdAt: createdAtDate,
            role: role ?? .user
        )
    }
}
