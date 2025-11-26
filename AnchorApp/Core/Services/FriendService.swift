import Foundation

enum FriendServiceError: Error {
    case network(Error)
    case decoding(Error)
    case invalidResponse
    case invalidUUID(String)
}

protocol FriendServiceProtocol {
    func fetchFriends() async throws -> [Friend]
    func searchUsers(query: String) async throws -> [User]
    func sendFriendRequest(to userId: String) async throws
    func respondToFriendRequest(requestId: String, accept: Bool) async throws
}

final class FriendService: FriendServiceProtocol {
    static let shared = FriendService()
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    func fetchFriends() async throws -> [Friend] {
        do {
            let dtos: [FriendDTO] = try await apiClient.request(.getFriends, responseType: [FriendDTO].self)
            return dtos.compactMap { $0.toFriend() }
        } catch let error as APIError {
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        do {
            let dtos: [UserDTO] = try await apiClient.request(.searchUsers(query: query), responseType: [UserDTO].self)
            return dtos.compactMap { $0.toUser() }
        } catch let error as APIError {
            if case .decodingError(let decodingError) = error {
                throw FriendServiceError.decoding(decodingError)
            }
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
    
    func sendFriendRequest(to userId: String) async throws {
        guard let friendId = UUID(uuidString: userId) else {
            throw FriendServiceError.invalidUUID(userId)
        }
        
        do {
            try await apiClient.request(.sendFriendRequest(friendId: friendId))
        } catch let error as APIError {
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
    
    func respondToFriendRequest(requestId: String, accept: Bool) async throws {
        guard let requestUUID = UUID(uuidString: requestId) else {
            throw FriendServiceError.invalidUUID(requestId)
        }
        
        do {
            if accept {
                try await apiClient.request(.acceptFriendRequest(requestId: requestUUID))
            } else {
                try await apiClient.request(.declineFriendRequest(requestId: requestUUID))
            }
        } catch let error as APIError {
            throw FriendServiceError.network(error)
        } catch {
            throw FriendServiceError.network(error)
        }
    }
}

