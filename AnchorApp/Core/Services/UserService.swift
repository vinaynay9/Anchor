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
        guard let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
              let userId = UUID(uuidString: userIdString) else {
            throw APIError.unauthorized
        }
        return try await getUser(id: userId)
    }
    
    func getUser(id: UUID) async throws -> User {
        let dto: UserDTO = try await apiClient.request(.getUser(id: id), responseType: UserDTO.self)
        guard let user = dto.toUser() else {
            throw APIError.decodingError(NSError(domain: "UserService", code: -1))
        }
        return user
    }
    
    func updateUser(username: String?, displayName: String?) async throws -> User {
        guard let userIdString = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
              let userId = UUID(uuidString: userIdString) else {
            throw APIError.unauthorized
        }
        
        let dto: UserDTO = try await apiClient.request(
            .updateUser(id: userId, username: username, displayName: displayName),
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

