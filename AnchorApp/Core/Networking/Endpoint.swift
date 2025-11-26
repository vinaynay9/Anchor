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
        if let token = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.accessToken) {
            defaultHeaders["Authorization"] = "Bearer \(token)"
        }
        return defaultHeaders
    }
}

extension APIEndpoint {
    var headers: [String: String]? {
        var headers: [String: String] = [
            "Accept": "application/json"
        ]
        
        // Add auth token if available
        if let token = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.accessToken) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        // Override Content-Type for multipart uploads
        switch self {
        case .uploadProof(let sessionId, let imageData):
            let (boundary, _) = createMultipartFormData(sessionId: sessionId, imageData: imageData)
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        default:
            headers["Content-Type"] = "application/json"
        }
        
        return headers
    }
    
    private func createMultipartFormData(sessionId: String, imageData: Data) -> (boundary: String, body: Data) {
        // Generate a deterministic boundary based on sessionId and imageData
        // This ensures headers and body use the same boundary
        var hasher = Hasher()
        hasher.combine(sessionId)
        hasher.combine(imageData.count)
        // Add a sample of the image data for uniqueness
        if imageData.count > 0 {
            let sampleSize = min(100, imageData.count)
            hasher.combine(imageData.prefix(sampleSize))
        }
        let hash = abs(hasher.finalize())
        let boundary = "----WebKitFormBoundary\(hash)"
        var body = Data()
        
        // Add sessionId field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"sessionId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(sessionId)\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"proof.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return (boundary, body)
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
    case uploadProof(sessionId: String, imageData: Data)
    case getProofs(sessionId: String)
    
    var path: String {
        switch self {
        case .signInApple: return "/auth/apple"
        case .signInGoogle: return "/auth/google"
        case .refreshToken: return "/auth/refresh"
        case .getUser(let id): return "/users/\(id.uuidString)"
        case .updateUser(let id, _, _): return "/users/\(id.uuidString)"
        case .searchUsers(let query): 
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            return "/users/search?q=\(encodedQuery)"
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
        case .getProofs(let sessionId): return "/proofs?session_id=\(sessionId)"
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
        case .uploadProof(let sessionId, let imageData):
            let (_, body) = createMultipartFormData(sessionId: sessionId, imageData: imageData)
            return body
        default:
            return nil
        }
    }
}

