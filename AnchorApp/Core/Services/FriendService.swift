import Foundation

enum FriendServiceError: Error {
    case network(Error)
    case decoding(Error)
    case invalidResponse
    case invalidUUID(String)
}

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
        do {
            let dtos: [FriendDTO] = try await apiClient.request(.getFriends, responseType: [FriendDTO].self)
            return dtos.compactMap { $0.toFriend() }
        } catch let error as APIError {
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
    
    // MARK: - POST /friends
    func addFriend(friendId: String) async throws {
        guard let friendUUID = UUID(uuidString: friendId) else {
            throw FriendServiceError.invalidUUID(friendId)
        }
        
        do {
            try await apiClient.request(.addFriend(friendId: friendUUID))
        } catch let error as APIError {
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
    
    // MARK: - DELETE /friends/{id}
    func deleteFriend(id: String) async throws {
        guard let friendUUID = UUID(uuidString: id) else {
            throw FriendServiceError.invalidUUID(id)
        }
        
        do {
            try await apiClient.request(.deleteFriend(id: friendUUID))
        } catch let error as APIError {
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
    
    // MARK: - GET /friends/requests
    func getFriendRequests() async throws -> [Friend] {
        do {
            let dtos: [FriendDTO] = try await apiClient.request(.getFriendRequests, responseType: [FriendDTO].self)
            return dtos.compactMap { $0.toFriend() }
        } catch let error as APIError {
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
    
    // MARK: - POST /friends/requests/{id}/accept
    func acceptFriendRequest(id: String) async throws {
        guard let requestUUID = UUID(uuidString: id) else {
            throw FriendServiceError.invalidUUID(id)
        }
        
        do {
            try await apiClient.request(.acceptFriendRequest(id: requestUUID))
        } catch let error as APIError {
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
    
    // MARK: - POST /friends/requests/{id}/reject
    func rejectFriendRequest(id: String) async throws {
        guard let requestUUID = UUID(uuidString: id) else {
            throw FriendServiceError.invalidUUID(id)
        }
        
        do {
            try await apiClient.request(.rejectFriendRequest(id: requestUUID))
        } catch let error as APIError {
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
}

