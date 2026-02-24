import SwiftUI
import Combine
import Shared

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var needsUsernameSetup: Bool = false
    
    private let authService: AuthServiceProtocol
    private let userService = UserService.shared
    
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
        loadCurrentUser()
    }
    
    func loadCurrentUser() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let user = try await authService.currentUser()
                await MainActor.run {
                    self.currentUser = user
                    if let user = user {
                        // Check if username is empty or needs setup
                        self.needsUsernameSetup = user.username.isEmpty
                    } else {
                        self.needsUsernameSetup = false
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.needsUsernameSetup = false
                    self.isLoading = false
                    self.handleAuthError(error, context: "loadCurrentUser")
                }
            }
        }
    }
    
    func handleAuthenticatedUser(_ user: User) {
        currentUser = user
        needsUsernameSetup = user.username.isEmpty
        errorMessage = nil
    }
    
    func completeUsernameSetup(_ username: String) {
        guard currentUser != nil else {
            errorMessage = "No user found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let updatedUser = try await userService.updateUser(username: username, displayName: nil)
                await MainActor.run {
                    self.currentUser = updatedUser
                    self.needsUsernameSetup = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleAuthError(error, context: "username")
                }
            }
        }
    }

    private func handleAuthError(_ error: Error, context _: String) {
        if let authError = error as? AuthError {
            switch authError {
            case .cancelled:
                errorMessage = "Sign in cancelled."
            case .invalidToken:
                errorMessage = "Sign in failed. Please try again."
            case .notAuthenticated:
                errorMessage = "Could not authenticate. Please try again."
            case .invalidCredentials:
                errorMessage = "Invalid email or password."
            case .failed(let underlying):
                let underlyingNSError = underlying as NSError
                errorMessage = "Sign in failed (\(underlyingNSError.domain) \(underlyingNSError.code))."
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            }
            return
        }

        errorMessage = error.localizedDescription
    }
}
