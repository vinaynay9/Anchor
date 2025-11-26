import Foundation

protocol FriendServiceProtocol {
    func getFriends() async throws -> [Friend]
    func getPendingRequests() async throws -> [Friend]
    func sendFriendRequest(friendId: UUID) async throws -> Friend
    func acceptFriendRequest(requestId: UUID) async throws -> Friend
    func declineFriendRequest(requestId: UUID) async throws
}

class FriendService: FriendServiceProtocol {
    static let shared = FriendService()
    
    private let apiClient = APIClient.shared
    
    func getFriends() async throws -> [Friend] {
        // TODO: Implement API response parsing
        // let dtos: [FriendDTO] = try await apiClient.request(.getFriends, responseType: [FriendDTO].self)
        // return dtos.compactMap { $0.toFriend() }
        return []
    }
    
    func getPendingRequests() async throws -> [Friend] {
        // TODO: Implement API response parsing
        return []
    }
    
    func sendFriendRequest(friendId: UUID) async throws -> Friend {
        // TODO: Implement API response parsing
        throw APIError.unknown
    }
    
    func acceptFriendRequest(requestId: UUID) async throws -> Friend {
        // TODO: Implement API response parsing
        throw APIError.unknown
    }
    
    func declineFriendRequest(requestId: UUID) async throws {
        try await apiClient.request(.declineFriendRequest(requestId: requestId))
    }
}

