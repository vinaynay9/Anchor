import Foundation
import Shared

enum AuthError: Error {
    case cancelled
    case failed(Error)
    case invalidToken
    case networkError
    case notAuthenticated
    case invalidCredentials
}

protocol AuthServiceProtocol {
    func signUp(email: String, password: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signOut() async throws
    func currentUser() async throws -> User?
}

class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private let apiClient = APIClient.shared
    private let keychainService = KeychainService.shared
    private let logger = LoggerService.shared
    private let userService = UserService.shared
    
    // MARK: - Email Auth
    func signUp(email: String, password: String) async throws -> User {
        logger.logInfo("Auth signup requested", category: "Auth")
        do {
            let response: AuthResponse = try await apiClient.request(
                .signUpEmail(email: email, password: password),
                responseType: AuthResponse.self
            )
            try storeTokens(from: response)
            logger.logInfo("Auth signup token stored", category: "Auth")
            let user = response.user.toUser()
            if let user {
                UserDefaults.standard.set(user.id.uuidString, forKey: AppConfig.UserDefaultsKeys.currentUserId)
                await postSignInProfileUpsert(email: user.email)
                logger.logInfo("Auth signup completed", category: "Auth")
                return user
            }
            throw AuthError.notAuthenticated
        } catch let error as AnchorAPIError {
            logger.logWarning("Auth signup failed: \(error)", category: "Auth")
            throw AuthError.failed(error)
        } catch {
            logger.logWarning("Auth signup failed: \(error.localizedDescription)", category: "Auth")
            throw AuthError.failed(error)
        }
    }

    func signIn(email: String, password: String) async throws -> User {
        logger.logInfo("Auth signin requested", category: "Auth")
        do {
            let response: AuthResponse = try await apiClient.request(
                .signInEmail(email: email, password: password),
                responseType: AuthResponse.self
            )
            try storeTokens(from: response)
            logger.logInfo("Auth signin token stored", category: "Auth")
            let user = response.user.toUser()
            if let user {
                UserDefaults.standard.set(user.id.uuidString, forKey: AppConfig.UserDefaultsKeys.currentUserId)
                await postSignInProfileUpsert(email: user.email)
                logger.logInfo("Auth signin completed", category: "Auth")
                return user
            }
            throw AuthError.notAuthenticated
        } catch let error as AnchorAPIError {
            if case .unauthorized = error {
                throw AuthError.invalidCredentials
            }
            logger.logWarning("Auth signin failed: \(error)", category: "Auth")
            throw AuthError.failed(error)
        } catch {
            logger.logWarning("Auth signin failed: \(error.localizedDescription)", category: "Auth")
            throw AuthError.failed(error)
        }
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        logger.logInfo("Auth sign out requested", category: "Auth")
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
            logger.logInfo("Auth current user fetch", category: "Auth")
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

    private func postSignInProfileUpsert(email: String?) async {
        guard let profile = AppGroupStorage.shared.getProfile() else {
            logger.logInfo("Profile upsert skipped: no local profile", category: "Auth")
            return
        }

        let displayName = profile.displayName
        let personal = AppGroupStorage.shared.getPersonalInfo()

        do {
            _ = try await userService.updateUserProfile(
                displayName: displayName,
                birthMonth: profile.birthMonth,
                birthDay: profile.birthDay,
                timezone: profile.timezone,
                email: email,
                firstName: personal?.firstName,
                lastName: personal?.lastName,
                birthday: personal?.birthday
            )
            logger.logInfo("Profile upsert success", category: "Auth")
        } catch {
            logger.logWarning("Profile upsert failed: \(error.localizedDescription)", category: "Auth")
        }
    }
    
    private func storeTokens(from response: AuthResponse) throws {
        let access = response.accessToken ?? response.token
        if let access {
            try keychainService.save(access, forKey: AppConfig.UserDefaultsKeys.accessToken)
        } else {
            logger.logWarning("Auth response missing access token", category: "Auth")
        }
        if let refresh = response.refreshToken {
            try keychainService.save(refresh, forKey: AppConfig.UserDefaultsKeys.refreshToken)
        }
    }
}
