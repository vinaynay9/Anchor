import Foundation
import Shared

protocol UserServiceProtocol {
    func getCurrentUser() async throws -> User
    func getUser(id: UUID) async throws -> User
    func updateUser(username: String?, displayName: String?) async throws -> User
    func updateUserProfile(
        displayName: String?,
        birthMonth: Int?,
        birthDay: Int?,
        timezone: String?,
        email: String?,
        firstName: String?,
        lastName: String?,
        birthday: String?
    ) async throws -> User
    func searchUsers(query: String) async throws -> [User]
}

class UserService: UserServiceProtocol {
    static let shared = UserService()
    
    private let apiClient = APIClient.shared
    
    func getCurrentUser() async throws -> User {
        // GET /user/me
        let dto: UserDTO = try await apiClient.request(.getCurrentUser, responseType: UserDTO.self)
        guard let user = dto.toUser() else {
            throw AnchorAPIError.decodingError(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode user from DTO"]))
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
        throw AnchorAPIError.unauthorized
    }
    
    func updateUser(username: String?, displayName: String?) async throws -> User {
        // PATCH /user/me
        let dto: UserDTO = try await apiClient.request(
            .updateCurrentUser(
                username: username,
                displayName: displayName,
                birthMonth: nil,
                birthDay: nil,
                timezone: nil,
                email: nil,
                firstName: nil,
                lastName: nil,
                birthday: nil
            ),
            responseType: UserDTO.self
        )
        guard let user = dto.toUser() else {
            throw AnchorAPIError.decodingError(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode user from DTO"]))
        }
        return user
    }

    func updateUserProfile(
        displayName: String?,
        birthMonth: Int?,
        birthDay: Int?,
        timezone: String?,
        email: String?,
        firstName: String?,
        lastName: String?,
        birthday: String?
    ) async throws -> User {
        let dto: UserDTO = try await apiClient.request(
            .updateCurrentUser(
                username: nil,
                displayName: displayName,
                birthMonth: birthMonth,
                birthDay: birthDay,
                timezone: timezone,
                email: email,
                firstName: firstName,
                lastName: lastName,
                birthday: birthday
            ),
            responseType: UserDTO.self
        )
        guard let user = dto.toUser() else {
            throw AnchorAPIError.decodingError(NSError(domain: "UserService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode user from DTO"]))
        }
        return user
    }
    
    func searchUsers(query: String) async throws -> [User] {
        // GET /users/search?query=...
        let dtos: [UserDTO] = try await apiClient.request(
            .searchUsers(query: query),
            responseType: [UserDTO].self
        )
        return dtos.compactMap { $0.toUser() }
    }
}
