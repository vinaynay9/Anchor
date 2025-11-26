import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}

extension Endpoint {
    var headers: [String: String]? {
        var defaultHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        // Add auth token if available
        if let token = AppConfig.UserDefaultsKeys.accessToken as? String {
            defaultHeaders["Authorization"] = "Bearer \(token)"
        }
        return defaultHeaders
    }
}

// MARK: - API Endpoints
enum APIEndpoint: Endpoint {
    // Auth
    case signInApple(token: String)
    case signInGoogle(token: String)
    case refreshToken(refreshToken: String)
    
    // Users
    case getUser(id: UUID)
    case updateUser(id: UUID, username: String?, displayName: String?)
    case searchUsers(query: String)
    
    // Friends
    case getFriends
    case getPendingRequests
    case sendFriendRequest(friendId: UUID)
    case acceptFriendRequest(requestId: UUID)
    case declineFriendRequest(requestId: UUID)
    
    // Sessions
    case createSession(session: LockSession)
    case getSession(id: UUID)
    case getActiveSession
    case updateSession(id: UUID, status: SessionStatus)
    case endSession(id: UUID)
    
    // Unlock Requests
    case createUnlockRequest(request: UnlockRequest)
    case getUnlockRequest(id: UUID)
    case getPendingUnlockRequests
    case approveUnlockRequest(id: UUID)
    case denyUnlockRequest(id: UUID)
    
    // Proofs
    case uploadProof(proof: Proof, imageData: Data)
    case getProofs(sessionId: UUID)
    
    var path: String {
        switch self {
        case .signInApple: return "/auth/apple"
        case .signInGoogle: return "/auth/google"
        case .refreshToken: return "/auth/refresh"
        case .getUser(let id): return "/users/\(id.uuidString)"
        case .updateUser(let id, _, _): return "/users/\(id.uuidString)"
        case .searchUsers: return "/users/search"
        case .getFriends: return "/friends"
        case .getPendingRequests: return "/friends/pending"
        case .sendFriendRequest: return "/friends/request"
        case .acceptFriendRequest: return "/friends/accept"
        case .declineFriendRequest: return "/friends/decline"
        case .createSession: return "/sessions"
        case .getSession(let id): return "/sessions/\(id.uuidString)"
        case .getActiveSession: return "/sessions/active"
        case .updateSession(let id, _): return "/sessions/\(id.uuidString)"
        case .endSession(let id): return "/sessions/\(id.uuidString)/end"
        case .createUnlockRequest: return "/unlock-requests"
        case .getUnlockRequest(let id): return "/unlock-requests/\(id.uuidString)"
        case .getPendingUnlockRequests: return "/unlock-requests/pending"
        case .approveUnlockRequest(let id): return "/unlock-requests/\(id.uuidString)/approve"
        case .denyUnlockRequest(let id): return "/unlock-requests/\(id.uuidString)/deny"
        case .uploadProof: return "/proofs/upload"
        case .getProofs: return "/proofs"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getUser, .getFriends, .getPendingRequests, .getSession, .getActiveSession,
             .getUnlockRequest, .getPendingUnlockRequests, .searchUsers, .getProofs:
            return .get
        case .signInApple, .signInGoogle, .refreshToken, .sendFriendRequest,
             .createSession, .createUnlockRequest, .uploadProof:
            return .post
        case .updateUser, .updateSession, .acceptFriendRequest, .declineFriendRequest,
             .approveUnlockRequest, .denyUnlockRequest:
            return .put
        case .endSession:
            return .delete
        }
    }
    
    var body: Data? {
        switch self {
        case .signInApple(let token):
            return try? JSONEncoder().encode(["token": token])
        case .signInGoogle(let token):
            return try? JSONEncoder().encode(["token": token])
        case .refreshToken(let refreshToken):
            return try? JSONEncoder().encode(["refresh_token": refreshToken])
        case .updateUser(_, let username, let displayName):
            var dict: [String: Any] = [:]
            if let username = username { dict["username"] = username }
            if let displayName = displayName { dict["display_name"] = displayName }
            return try? JSONSerialization.data(withJSONObject: dict)
        case .sendFriendRequest(let friendId):
            return try? JSONEncoder().encode(["friend_id": friendId.uuidString])
        case .acceptFriendRequest(let requestId):
            return try? JSONEncoder().encode(["request_id": requestId.uuidString])
        case .declineFriendRequest(let requestId):
            return try? JSONEncoder().encode(["request_id": requestId.uuidString])
        case .createSession(let session):
            return try? JSONEncoder().encode(session)
        case .updateSession(_, let status):
            return try? JSONEncoder().encode(["status": status.rawValue])
        case .createUnlockRequest(let request):
            return try? JSONEncoder().encode(request)
        case .uploadProof(let proof, let imageData):
            // TODO: Implement multipart form data encoding
            return nil
        default:
            return nil
        }
    }
}

