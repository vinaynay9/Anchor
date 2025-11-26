import Foundation
import AuthenticationServices
import GoogleSignIn

enum AuthProvider {
    case apple
    case google
}

enum AuthError: Error {
    case cancelled
    case failed(Error)
    case invalidToken
    case networkError
}

protocol AuthServiceProtocol {
    func signIn(with provider: AuthProvider) async throws -> (token: String, user: User)
    func signOut() async throws
    func refreshToken() async throws -> String
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private let apiClient = APIClient.shared
    private let supabaseClient = SupabaseClient.shared
    
    // MARK: - Apple Sign In
    func signIn(with provider: AuthProvider) async throws -> (token: String, user: User) {
        switch provider {
        case .apple:
            return try await signInWithApple()
        case .google:
            return try await signInWithGoogle()
        }
    }
    
    private func signInWithApple() async throws -> (token: String, user: User) {
        // TODO: Implement Apple Sign In
        // 1. Request authorization with ASAuthorizationAppleIDProvider
        // 2. Get identity token
        // 3. Send token to backend via APIEndpoint.signInApple
        // 4. Receive access token and user data
        // 5. Store tokens securely (Keychain)
        // 6. Return token and user
        
        throw AuthError.failed(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple Sign In not yet implemented"]))
    }
    
    private func signInWithGoogle() async throws -> (token: String, user: User) {
        // TODO: Implement Google Sign In
        // 1. Configure GIDSignIn with client ID
        // 2. Present sign-in flow
        // 3. Get ID token
        // 4. Send token to backend via APIEndpoint.signInGoogle
        // 5. Receive access token and user data
        // 6. Store tokens securely (Keychain)
        // 7. Return token and user
        
        throw AuthError.failed(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign In not yet implemented"]))
    }
    
    func signOut() async throws {
        // TODO: Implement sign out
        // 1. Call backend to invalidate token
        // 2. Clear local tokens from Keychain
        // 3. Clear UserDefaults
        // 4. Reset SupabaseClient auth state
        
        supabaseClient.clearAuthToken()
        UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.currentUserId)
    }
    
    func refreshToken() async throws -> String {
        // TODO: Implement token refresh
        // 1. Get refresh token from Keychain
        // 2. Call APIEndpoint.refreshToken
        // 3. Store new access token
        // 4. Return new token
        
        throw AuthError.failed(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token refresh not yet implemented"]))
    }
}

