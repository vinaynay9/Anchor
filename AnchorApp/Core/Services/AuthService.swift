import Foundation
import Shared

enum AuthError: Error {
    case cancelled
    case failed(Error)
    case invalidToken
    case networkError
    case notAuthenticated
    case configurationMissing
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
    private let cognitoAuthService = CognitoAuthService.shared
    private let logger = LoggerService.shared
    private let userService = UserService.shared
    
    // MARK: - Apple Sign In
    func signInWithApple() async throws -> User {
        guard !AppConfig.cognitoDomain.isEmpty,
              !AppConfig.cognitoClientId.isEmpty,
              !AppConfig.cognitoRedirectURI.isEmpty else {
            throw AuthError.configurationMissing
        }

        do {
            try await cognitoAuthService.signIn(provider: .apple)
        } catch {
            throw AuthError.failed(error)
        }

        guard let idToken = await cognitoAuthService.getValidIdToken() else {
            throw AuthError.invalidToken
        }

        try keychainService.save(idToken, forKey: AppConfig.UserDefaultsKeys.accessToken)
        let user = try await currentUserOrNil()
        if let user {
            await postSignInProfileUpsert()
            return user
        }
        throw AuthError.notAuthenticated
    }

    // MARK: - Google Sign In (via Cognito Hosted UI)
    func signInWithGoogle() async throws -> User {
        guard !AppConfig.cognitoDomain.isEmpty,
              !AppConfig.cognitoClientId.isEmpty,
              !AppConfig.cognitoRedirectURI.isEmpty else {
            throw AuthError.configurationMissing
        }

        do {
            try await cognitoAuthService.signIn(provider: .google)
        } catch {
            throw AuthError.failed(error)
        }

        guard let idToken = await cognitoAuthService.getValidIdToken() else {
            throw AuthError.invalidToken
        }

        // Store token so APIClient can use it for /user/me
        try keychainService.save(idToken, forKey: AppConfig.UserDefaultsKeys.accessToken)

        let user = try await currentUserOrNil()
        if let user {
            await postSignInProfileUpsert()
            return user
        }
        throw AuthError.notAuthenticated
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
        cognitoAuthService.signOutLocal()
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

    private func currentUserOrNil() async throws -> User? {
        do {
            return try await currentUser()
        } catch {
            return nil
        }
    }

    private func postSignInProfileUpsert() async {
        let claims = await decodeIDTokenClaims()
        let email = claims["email"] as? String
        let fullName = claims["name"] as? String
        let givenName = claims["given_name"] as? String
        let familyName = claims["family_name"] as? String

        guard let profile = AppGroupStorage.shared.getProfile() else {
            logger.logInfo("Profile upsert skipped: no local profile", category: "Auth")
            return
        }

        let displayName = profile.displayName.isEmpty ? (fullName ?? profile.displayName) : profile.displayName

        do {
            _ = try await userService.updateUserProfile(
                displayName: displayName,
                birthMonth: profile.birthMonth,
                birthDay: profile.birthDay,
                timezone: profile.timezone,
                email: email,
                fullName: fullName,
                givenName: givenName,
                familyName: familyName
            )
            logger.logInfo("Profile upsert success", category: "Auth")
        } catch {
            logger.logWarning("Profile upsert failed: \(error.localizedDescription)", category: "Auth")
        }
    }

    private func decodeIDTokenClaims() async -> [String: Any] {
        guard let idToken = await cognitoAuthService.getValidIdToken() else {
            return [:]
        }
        let segments = idToken.split(separator: ".")
        guard segments.count >= 2 else { return [:] }
        let payload = String(segments[1])
        let padded = payload.padBase64()
        guard let data = Data(base64Encoded: padded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }
}

private extension String {
    func padBase64() -> String {
        var result = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = 4 - (result.count % 4)
        if padding < 4 {
            result += String(repeating: "=", count: padding)
        }
        return result
    }
}
