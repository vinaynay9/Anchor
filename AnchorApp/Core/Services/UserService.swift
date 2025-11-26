import Foundation

protocol UserServiceProtocol {
    func getCurrentUser() async throws -> User
    func getUser(id: UUID) async throws -> User
    func updateUser(username: String?, displayName: String?) async throws -> User
    func searchUsers(query: String) async throws -> [User]
}

class UserService: UserServiceProtocol {
    static let shared = UserService()
    
    private let apiClient = APIClient.shared
    
    func getCurrentUser() async throws -> User {
        // GET /user/me
        let dto: UserDTO = try await apiClient.request(.getCurrentUser, responseType: UserDTO.self)
        guard let user = dto.toUser() else {
            throw APIError.decodingError(NSError(domain: "UserService", code: -1))
        }
        return user
    }
    
    func getUser(id: UUID) async throws -> User {
        // Use getCurrentUser for now, or implement separate endpoint if needed
        // For now, if requesting current user's ID, use /user/me
        if let currentUserIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
           let currentUserId = UUID(uuidString: currentUserIdString),
           currentUserId == id {
            return try await getCurrentUser()
        }
        throw APIError.unauthorized
    }
    
    func updateUser(username: String?, displayName: String?) async throws -> User {
        // PATCH /user/me
        let dto: UserDTO = try await apiClient.request(
            .updateCurrentUser(username: username, displayName: displayName),
            responseType: UserDTO.self
        )
        guard let user = dto.toUser() else {
            throw APIError.decodingError(NSError(domain: "UserService", code: -1))
        }
        return user
    }
    
    func searchUsers(query: String) async throws -> [User] {
        // TODO: Implement search endpoint response parsing
        // For now, return empty array
        return []
    }
}

