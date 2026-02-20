import Foundation
import Shared

protocol FriendServiceProtocol {
    func getFriends() async throws -> [Friend]
    func addFriend(friendId: String) async throws
    func deleteFriend(id: String) async throws
    func getFriendRequests() async throws -> [Friend]
    func acceptFriendRequest(id: String) async throws
    func rejectFriendRequest(id: String) async throws
}

final class FriendService: FriendServiceProtocol {
    static let shared = FriendService()
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - GET /friends
    func getFriends() async throws -> [Friend] {
        let dtos: [FriendDTO] = try await apiClient.request(.getFriends, responseType: [FriendDTO].self)
        return dtos.compactMap { $0.toFriend() }
    }
    
    // MARK: - POST /friends
    func addFriend(friendId: String) async throws {
        guard UUID(uuidString: friendId) != nil else {
            throw AnchorAPIError.unknown
        }
        
        guard let friendUUID = UUID(uuidString: friendId) else {
            throw AnchorAPIError.unknown
        }
        try await apiClient.request(.addFriend(friendId: friendUUID))
    }
    
    // MARK: - DELETE /friends/{id}
    func deleteFriend(id: String) async throws {
        guard let friendUUID = UUID(uuidString: id) else {
            throw AnchorAPIError.unknown
        }
        
        try await apiClient.request(.deleteFriend(id: friendUUID))
    }
    
    // MARK: - GET /friends/requests
    func getFriendRequests() async throws -> [Friend] {
        let dtos: [FriendDTO] = try await apiClient.request(.getFriendRequests, responseType: [FriendDTO].self)
        return dtos.compactMap { $0.toFriend() }
    }
    
    // MARK: - POST /friends/requests/{id}/accept
    func acceptFriendRequest(id: String) async throws {
        guard let requestUUID = UUID(uuidString: id) else {
            throw AnchorAPIError.unknown
        }
        
        try await apiClient.request(.acceptFriendRequest(id: requestUUID))
    }
    
    // MARK: - POST /friends/requests/{id}/reject
    func rejectFriendRequest(id: String) async throws {
        guard let requestUUID = UUID(uuidString: id) else {
            throw AnchorAPIError.unknown
        }
        
        try await apiClient.request(.rejectFriendRequest(id: requestUUID))
    }
}
