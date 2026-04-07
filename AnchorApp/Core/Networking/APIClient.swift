import Foundation

// MARK: - DebugNetworkBlocker Removal Notice
// DebugNetworkBlocker.swift was deleted.  It registered a URLProtocol subclass
// (BlockingURLProtocol) that intercepted ALL network traffic in DEBUG+simulator
// builds, returning NSURLErrorNotConnectedToInternet for every request that
// wasn't one of three hard-coded stubs (/auth/signup, /auth/signin, /user/me).
// This made the app completely untestable on the simulator.
//
// Now that the backend is Supabase the stubs are obsolete; all real network
// requests pass through unmodified.  The call site in AnchorAppApp.init() was
// also removed.

/// Unified error model for all Anchor API networking operations
enum AnchorAPIError: Error {
    /// Network-level error (connection failure, timeout, etc.)
    case networkError(Error)
    
    /// JSON decoding failed (malformed response, type mismatch, etc.)
    case decodingError(Error)
    
    /// Authentication failed (401 Unauthorized)
    case unauthorized
    
    /// Resource not found (404 Not Found)
    case notFound
    
    /// Server error with status code (5xx responses)
    case serverError(code: Int)
    
    /// Unknown or unhandled error
    case unknown

    /// Missing backend configuration (legacy callers may map to this)
    case configurationMissing

}

class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let baseURL: URL
    
    init(session: URLSession? = nil, baseURL: URL = AppConfig.baseURL) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            self.session = URLSession(configuration: config)
        }
        self.baseURL = baseURL
    }
    
    func request<T: Decodable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        let url: URL
        if endpoint.path.contains("?") {
            // Handle query strings in path
            let pathParts = endpoint.path.components(separatedBy: "?")
            let path = pathParts.first ?? endpoint.path
            let query = pathParts.dropFirst().joined(separator: "?")
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components?.path = path
            components?.query = query.isEmpty ? nil : query
            guard let constructedURL = components?.url else {
                throw AnchorAPIError.unknown
            }
            url = constructedURL
        } else {
            url = baseURL.appendingPathComponent(endpoint.path)
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorAPIError.unknown
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Map HTTP status codes to unified error cases
                switch httpResponse.statusCode {
                case 401:
                    throw AnchorAPIError.unauthorized
                case 404:
                    throw AnchorAPIError.notFound
                case 500...599:
                    throw AnchorAPIError.serverError(code: httpResponse.statusCode)
                default:
                    throw AnchorAPIError.serverError(code: httpResponse.statusCode)
                }
            }
            
            // Handle 204 No Content - return empty data error that can be caught by caller
            if httpResponse.statusCode == 204 || data.isEmpty {
                throw AnchorAPIError.decodingError(NSError(domain: "APIClient", code: 204, userInfo: [NSLocalizedDescriptionKey: "No content (204) or empty response body"]))
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw AnchorAPIError.decodingError(error)
            }
        } catch let error as AnchorAPIError {
            throw error
        } catch {
            throw AnchorAPIError.networkError(error)
        }
    }
    
    func request(_ endpoint: APIEndpoint) async throws {
        let url: URL
        if endpoint.path.contains("?") {
            // Handle query strings in path
            let pathParts = endpoint.path.components(separatedBy: "?")
            let path = pathParts.first ?? endpoint.path
            let query = pathParts.dropFirst().joined(separator: "?")
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components?.path = path
            components?.query = query.isEmpty ? nil : query
            guard let constructedURL = components?.url else {
                throw AnchorAPIError.unknown
            }
            url = constructedURL
        } else {
            url = baseURL.appendingPathComponent(endpoint.path)
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorAPIError.unknown
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Map HTTP status codes to unified error cases
                switch httpResponse.statusCode {
                case 401:
                    throw AnchorAPIError.unauthorized
                case 404:
                    throw AnchorAPIError.notFound
                case 500...599:
                    throw AnchorAPIError.serverError(code: httpResponse.statusCode)
                default:
                    throw AnchorAPIError.serverError(code: httpResponse.statusCode)
                }
            }
        } catch let error as AnchorAPIError {
            throw error
        } catch {
            throw AnchorAPIError.networkError(error)
        }
    }
}
