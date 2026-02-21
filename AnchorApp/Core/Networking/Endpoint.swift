import Foundation
import Shared

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
        // Add auth token if available (from Keychain)
        if let token = try? KeychainService.shared.get(forKey: AppConfig.UserDefaultsKeys.accessToken) {
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
        
        // Add auth token if available (from Keychain)
        if let token = try? KeychainService.shared.get(forKey: AppConfig.UserDefaultsKeys.accessToken) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        // Override Content-Type for multipart uploads
        switch self {
        case .uploadProof(let sessionId, let imageData):
            let (boundary, _) = createMultipartFormData(sessionId: sessionId, imageData: imageData)
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        case .getCurrentUser, .getFriends, .getFriendRequests, .getActiveSession, 
             .getPendingUnlockRequests, .getProof, .getProofsForUser, .searchUsers,
             .getActivityFeed:
            // GET requests don't need Content-Type
            break
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
        guard
            let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
            let sessionHeader = "Content-Disposition: form-data; name=\"sessionId\"\r\n\r\n".data(using: .utf8),
            let sessionValue = "\(sessionId)\r\n".data(using: .utf8),
            let fileHeader = "Content-Disposition: form-data; name=\"file\"; filename=\"proof.jpg\"\r\n".data(using: .utf8),
            let fileType = "Content-Type: image/jpeg\r\n\r\n".data(using: .utf8),
            let footer = "\r\n".data(using: .utf8),
            let closing = "--\(boundary)--\r\n".data(using: .utf8)
        else {
            return (boundary, Data())
        }
        body.append(boundaryData)
        body.append(sessionHeader)
        body.append(sessionValue)
        
        // Add file field
        body.append(boundaryData)
        body.append(fileHeader)
        body.append(fileType)
        body.append(imageData)
        body.append(footer)
        
        // Add closing boundary
        body.append(closing)
        
        return (boundary, body)
    }
}

// MARK: - API Endpoints
enum APIEndpoint: Endpoint {
    // Auth
    case signInApple(token: String)
    case signOut
    case getCurrentUser
    case updateCurrentUser(
        username: String?,
        displayName: String?,
        birthMonth: Int?,
        birthDay: Int?,
        timezone: String?,
        email: String?,
        fullName: String?,
        givenName: String?,
        familyName: String?
    )
    case searchUsers(query: String)
    
    // Friends
    case getFriends
    case addFriend(friendId: UUID)
    case deleteFriend(id: UUID)
    case getFriendRequests
    case acceptFriendRequest(id: UUID)
    case rejectFriendRequest(id: UUID)
    
    // Sessions
    case startSession(session: LockSession)
    case endSession(sessionId: UUID)
    case getActiveSession
    
    // Unlock Requests
    case createUnlockRequest(request: UnlockRequest)
    case getPendingUnlockRequests
    case approveUnlockRequest(id: UUID)
    case rejectUnlockRequest(id: UUID)
    case cancelUnlockRequest(sessionId: UUID)
    
    // Proofs
    case uploadProof(sessionId: String, imageData: Data)
    case getProof(id: UUID)
    case getProofsForUser(userId: UUID)
    
    // Notifications
    case registerDeviceToken(token: String)
    
    // Activity Feed
    case getActivityFeed
    
    // Invites
    case inviteStats(inviterId: String, inviteCode: String)
    case inviteAttribution(inviterId: String, inviteCode: String, deviceId: String)
    
    var path: String {
        switch self {
        // Auth
        case .signInApple: return "/auth/apple"
        case .signOut: return "/auth/signout"
        case .getCurrentUser: return "/user/me"
        case .updateCurrentUser: return "/user/me"
        case .searchUsers(let query):
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "/users/search?query=\(encodedQuery)"
        
        // Friends
        case .getFriends: return "/friends"
        case .addFriend: return "/friends"
        case .deleteFriend(let id): return "/friends/\(id.uuidString)"
        case .getFriendRequests: return "/friends/requests"
        case .acceptFriendRequest(let id): return "/friends/requests/\(id.uuidString)/accept"
        case .rejectFriendRequest(let id): return "/friends/requests/\(id.uuidString)/reject"
        
        // Sessions
        case .startSession: return "/sessions/start"
        case .endSession: return "/sessions/end"
        case .getActiveSession: return "/sessions/active"
        
        // Unlock Requests
        case .createUnlockRequest: return "/unlock-requests"
        case .getPendingUnlockRequests: return "/unlock-requests/pending"
        case .approveUnlockRequest(let id): return "/unlock-requests/\(id.uuidString)/approve"
        case .rejectUnlockRequest(let id): return "/unlock-requests/\(id.uuidString)/reject"
        case .cancelUnlockRequest(let sessionId): return "/unlock-requests/cancel?sessionId=\(sessionId.uuidString)"
        
        // Proofs
        case .uploadProof: return "/proofs"
        case .getProof(let id): return "/proofs/\(id.uuidString)"
        case .getProofsForUser(let userId): return "/proofs/user/\(userId.uuidString)"
        
        // Notifications
        case .registerDeviceToken: return "/notifications/device-token"
        
        // Activity Feed
        case .getActivityFeed: return "/activity/feed"
        
        // Invites
        case .inviteStats(let inviterId, let inviteCode):
            let inviter = inviterId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let code = inviteCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "/invite/stats?inviterId=\(inviter)&inviteCode=\(code)"
        case .inviteAttribution:
            return "/invite/attribution"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        // GET
        case .getCurrentUser, .getFriends, .getFriendRequests, .getActiveSession,
             .getPendingUnlockRequests, .getProof, .getProofsForUser, .searchUsers,
             .getActivityFeed, .inviteStats:
            return .get
        
        // POST
        case .signInApple, .signOut, .addFriend, .startSession, .endSession,
             .createUnlockRequest, .uploadProof, .registerDeviceToken,
             .acceptFriendRequest, .rejectFriendRequest,
             .approveUnlockRequest, .rejectUnlockRequest, .cancelUnlockRequest,
             .inviteAttribution:
            return .post
        
        // PATCH
        case .updateCurrentUser:
            return .patch
        
        // DELETE
        case .deleteFriend:
            return .delete
        }
    }
    
    var body: Data? {
        switch self {
        // Auth
        case .signInApple(let token):
            return try? JSONEncoder().encode(["token": token])
        case .updateCurrentUser(let username, let displayName, let birthMonth, let birthDay, let timezone, let email, let fullName, let givenName, let familyName):
            var dict: [String: Any] = [:]
            if let username = username { dict["username"] = username }
            if let displayName = displayName { dict["display_name"] = displayName }
            if let birthMonth = birthMonth { dict["birth_month"] = birthMonth }
            if let birthDay = birthDay { dict["birth_day"] = birthDay }
            if let timezone = timezone { dict["timezone"] = timezone }
            if let email = email { dict["email"] = email }
            if let fullName = fullName { dict["name"] = fullName }
            if let givenName = givenName { dict["given_name"] = givenName }
            if let familyName = familyName { dict["family_name"] = familyName }
            return try? JSONSerialization.data(withJSONObject: dict)
        
        // Friends
        case .addFriend(let friendId):
            return try? JSONEncoder().encode(["friend_id": friendId.uuidString])
        case .acceptFriendRequest, .rejectFriendRequest:
            // These endpoints don't require a body, just the ID in the path
            return nil
        
        // Sessions
        case .startSession(let session):
            return try? JSONEncoder().encode(session)
        case .endSession(let sessionId):
            return try? JSONEncoder().encode(["session_id": sessionId.uuidString])
        
        // Unlock Requests
        case .createUnlockRequest(let request):
            return try? JSONEncoder().encode(request)
        case .approveUnlockRequest, .rejectUnlockRequest:
            // These endpoints don't require a body, just the ID in the path
            return nil
        
        // Proofs
        case .uploadProof(let sessionId, let imageData):
            let (_, body) = createMultipartFormData(sessionId: sessionId, imageData: imageData)
            return body
        
        // Notifications
        case .registerDeviceToken(let token):
            return try? JSONEncoder().encode(["device_token": token])
        
        // Invites
        case .inviteAttribution(let inviterId, let inviteCode, let deviceId):
            return try? JSONEncoder().encode([
                "inviter_id": inviterId,
                "invite_code": inviteCode,
                "device_id": deviceId
            ])
        
        // No body needed
        default:
            return nil
        }
    }
}
