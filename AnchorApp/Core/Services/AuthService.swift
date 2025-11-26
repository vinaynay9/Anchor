import Foundation
import Shared

enum AuthError: Error {
    case cancelled
    case failed(Error)
    case invalidToken
    case networkError
    case notAuthenticated
}

protocol AuthServiceProtocol {
    func signInWithApple() async throws -> User
    func signInWithGoogle() async throws -> User
    func signOut() async throws
    func currentUser() async throws -> User?
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private let apiClient = APIClient.shared
    
    // MARK: - Apple Sign In
    func signInWithApple() async throws -> User {
        // TODO: Integrate Apple SDK
        // 1. Request authorization with ASAuthorizationAppleIDProvider
        // 2. Get identity token
        // 3. Send token to backend via APIEndpoint.signInApple
        // 4. Receive access token and user data
        // 5. Store tokens securely (Keychain)
        // 6. Store user ID in UserDefaults
        // 7. Return user
        
        // TODO: Get identity token from Apple Sign In
        let identityToken = "placeholder_token" // Replace with actual token from Apple SDK
        
        // POST /auth/apple
        struct AuthResponse: Codable {
            let accessToken: String
            let refreshToken: String?
            let user: UserDTO
        }
        
        let response: AuthResponse = try await apiClient.request(
            .signInApple(token: identityToken),
            responseType: AuthResponse.self
        )
        
        // Store tokens
        UserDefaults.standard.set(response.accessToken, forKey: AppConfig.UserDefaultsKeys.accessToken)
        if let refreshToken = response.refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: AppConfig.UserDefaultsKeys.refreshToken)
        }
        
        guard let user = response.user.toUser() else {
            throw AuthError.invalidToken
        }
        
        // Store user ID
        UserDefaults.standard.set(user.id.uuidString, forKey: AppConfig.UserDefaultsKeys.currentUserId)
        
        return user
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async throws -> User {
        // TODO: Integrate Google SDK
        // 1. Configure GIDSignIn with client ID
        // 2. Present sign-in flow
        // 3. Get ID token
        // 4. Send token to backend via APIEndpoint.signInGoogle
        // 5. Receive access token and user data
        // 6. Store tokens securely (Keychain)
        // 7. Store user ID in UserDefaults
        // 8. Return user
        
        // Simulate async call with delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // Mock implementation - return a mock user
        let mockUser = User(
            id: UUID(),
            email: "user@gmail.com",
            username: "",
            displayName: "Google User",
            createdAt: Date()
        )
        
        // Store user ID for currentUser() to retrieve
        UserDefaults.standard.set(mockUser.id.uuidString, forKey: AppConfig.UserDefaultsKeys.currentUserId)
        
        // TODO: Send identity token to backend
        // let identityToken = "..." // Get from Google Sign In
        // let response: AuthResponse = try await apiClient.request(
        //     .signInGoogle(token: identityToken),
        //     responseType: AuthResponse.self
        // )
        // Store access token: UserDefaults.standard.set(response.accessToken, forKey: AppConfig.UserDefaultsKeys.accessToken)
        
        return mockUser
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        // TODO: Call backend to invalidate token
        // try await apiClient.request(.signOut)
        
        // Clear local storage
        UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.currentUserId)
        UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.accessToken)
        UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.refreshToken)
        
        // TODO: Clear tokens from Keychain
    }
    
    // MARK: - Current User
    func currentUser() async throws -> User? {
        // GET /user/me
        do {
            let dto: UserDTO = try await apiClient.request(.getCurrentUser, responseType: UserDTO.self)
            guard let user = dto.toUser() else {
                return nil
            }
            
            // Update stored user ID
            UserDefaults.standard.set(user.id.uuidString, forKey: AppConfig.UserDefaultsKeys.currentUserId)
            
            return user
        } catch {
            // If unauthorized, clear stored user ID
            if case APIError.unauthorized = error {
                UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.currentUserId)
            }
            throw AuthError.notAuthenticated
        }
    }
}

