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

        if let token = try? KeychainService.shared.get(forKey: AppConfig.UserDefaultsKeys.accessToken) {
            headers["Authorization"] = "Bearer \(token)"
        }

        switch self {
        case .getCurrentUser:
            break
        default:
            headers["Content-Type"] = "application/json"
        }

        return headers
    }
}

// MARK: - API Endpoints
enum APIEndpoint: Endpoint {
    // Auth
    case signInApple(token: String)
    case signInGoogle(token: String)
    case signOut
    case getCurrentUser
    
    var path: String {
        switch self {
        // Auth
        case .signInApple: return "/auth/apple"
        case .signInGoogle: return "/auth/google"
        case .signOut: return "/auth/signout"
        case .getCurrentUser: return "/user/me"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        // GET
        case .getCurrentUser:
            return .get
        
        // POST
        case .signInApple, .signInGoogle, .signOut:
            return .post
        }
    }
    
    var body: Data? {
        switch self {
        // Auth
        case .signInApple(let token):
            return try? JSONEncoder().encode(["token": token])
        case .signInGoogle(let token):
            return try? JSONEncoder().encode(["token": token])
        
        // No body needed
        default:
            return nil
        }
    }
}
