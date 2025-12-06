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
    private let keychainService = KeychainService.shared
    private let googleSignInCoordinator = GoogleSignInCoordinator.shared
    private let appleSignInCoordinator = AppleSignInCoordinator()
    
    // MARK: - Apple Sign In
    func signInWithApple() async throws -> User {
        // 1. Request authorization with ASAuthorizationAppleIDProvider
        // 2. Get identity token
        let identityToken: String
        do {
            identityToken = try await appleSignInCoordinator.performSignIn()
        } catch let error as AppleSignInError {
            switch error {
            case .cancelled:
                throw AuthError.cancelled
            case .failed(let underlyingError):
                throw AuthError.failed(underlyingError)
            case .invalidToken, .invalidResponse:
                throw AuthError.invalidToken
            }
        }
        
        // 3. Send token to backend via APIEndpoint.signInApple
        struct AuthResponse: Codable {
            let accessToken: String
            let refreshToken: String?
            let user: UserDTO
        }
        
        let response: AuthResponse = try await apiClient.request(
            .signInApple(token: identityToken),
            responseType: AuthResponse.self
        )
        
        // 4. Store tokens securely in Keychain
        try keychainService.save(response.accessToken, forKey: AppConfig.UserDefaultsKeys.accessToken)
        if let refreshToken = response.refreshToken {
            try keychainService.save(refreshToken, forKey: AppConfig.UserDefaultsKeys.refreshToken)
        }
        
        guard let user = response.user.toUser() else {
            throw AuthError.invalidToken
        }
        
        // 5. Store user ID in UserDefaults
        UserDefaults.standard.set(user.id.uuidString, forKey: AppConfig.UserDefaultsKeys.currentUserId)
        
        return user
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async throws -> User {
        // 1. Get ID token from Google Sign-In
        let idToken: String
        do {
            idToken = try await googleSignInCoordinator.signIn()
        } catch let error as GoogleSignInError {
            switch error {
            case .cancelled:
                throw AuthError.cancelled
            case .noIDToken, .noPresentingViewController:
                throw AuthError.invalidToken
            case .signInFailed(let underlyingError):
                throw AuthError.failed(underlyingError)
            }
        } catch {
            throw AuthError.failed(error)
        }
        
        // 2. Send ID token to backend
        struct AuthResponse: Codable {
            let accessToken: String
            let refreshToken: String?
            let user: UserDTO
        }
        
        let response: AuthResponse
        do {
            response = try await apiClient.request(
                .signInGoogle(token: idToken),
                responseType: AuthResponse.self
            )
        } catch let error as AnchorAPIError {
            // Convert AnchorAPIError to AuthError for consistency with existing error handling
            switch error {
            case .unauthorized:
                throw AuthError.invalidToken
            case .networkError:
                throw AuthError.networkError
            default:
                throw AuthError.failed(error)
            }
        } catch {
            throw AuthError.failed(error)
        }
        
        // 3. Store access token in Keychain
        do {
            try keychainService.save(response.accessToken, forKey: AppConfig.UserDefaultsKeys.accessToken)
        } catch {
            throw AuthError.failed(error)
        }
        
        // 4. Store refresh token in Keychain if available
        if let refreshToken = response.refreshToken {
            do {
                try keychainService.save(refreshToken, forKey: AppConfig.UserDefaultsKeys.refreshToken)
            } catch {
                // Log error but don't fail - refresh token is optional
                print("Warning: Failed to save refresh token to Keychain: \(error)")
            }
        }
        
        // 5. Convert DTO to User
        guard let user = response.user.toUser() else {
            throw AuthError.invalidToken
        }
        
        // 6. Store user ID in UserDefaults
        UserDefaults.standard.set(user.id.uuidString, forKey: AppConfig.UserDefaultsKeys.currentUserId)
        
        return user
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        // Call backend to invalidate token
        do {
            try await apiClient.request(.signOut)
        } catch {
            // Continue with local cleanup even if backend call fails
            // This ensures user can still sign out locally
        }
        
        // Clear local storage
        UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.currentUserId)
        
        // Clear tokens from Keychain
        try? keychainService.delete(forKey: AppConfig.UserDefaultsKeys.accessToken)
        try? keychainService.delete(forKey: AppConfig.UserDefaultsKeys.refreshToken)
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
        } catch let error as AnchorAPIError {
            // If unauthorized, clear stored user ID
            if case .unauthorized = error {
                UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.currentUserId)
            }
            throw AuthError.notAuthenticated
        } catch {
            throw AuthError.notAuthenticated
        }
    }
}

