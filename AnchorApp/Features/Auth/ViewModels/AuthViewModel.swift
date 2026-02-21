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
    private let authDiagnostics = AuthDiagnostics.shared
    
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
    
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let user = try await authService.signInWithApple()
                await MainActor.run {
                    self.currentUser = user
                    self.needsUsernameSetup = user.username.isEmpty
                    self.isLoading = false
                    self.authDiagnostics.clear()
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.needsUsernameSetup = false
                    self.isLoading = false
                    self.handleAuthError(error, context: "apple")
                }
            }
        }
    }

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let user = try await authService.signInWithGoogle()
                await MainActor.run {
                    self.currentUser = user
                    self.needsUsernameSetup = user.username.isEmpty
                    self.isLoading = false
                    self.authDiagnostics.clear()
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.needsUsernameSetup = false
                    self.isLoading = false
                    self.handleAuthError(error, context: "google")
                }
            }
        }
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

    private func handleAuthError(_ error: Error, context: String) {
        authDiagnostics.record(error: error, context: context)
        let nsError = error as NSError

        if nsError.domain == "AKAuthenticationError" && nsError.code == -7026 {
            errorMessage = "Apple Sign In isn’t available on this simulator. Try on a real device or use Google."
            return
        }

        if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" && nsError.code == 1000 {
            errorMessage = "Apple Sign In isn’t available on this simulator. Try on a real device or use Google."
            return
        }

        if let authError = error as? AuthError {
            switch authError {
            case .configurationMissing:
                errorMessage = "Google Sign-In is not configured. Update Cognito settings in Secrets."
            case .cancelled:
                errorMessage = "Sign in cancelled."
            case .invalidToken:
                errorMessage = "Sign in failed. Please try again."
            case .notAuthenticated:
                errorMessage = "Could not authenticate. Please try again."
            case .failed(let underlying):
                let underlyingNSError = underlying as NSError
                if underlyingNSError.domain == "AKAuthenticationError" && underlyingNSError.code == -7026 {
                    errorMessage = "Apple Sign In isn’t available on this simulator. Try on a real device or use Google."
                } else if underlyingNSError.domain == "com.apple.AuthenticationServices.AuthorizationError" && underlyingNSError.code == 1000 {
                    errorMessage = "Apple Sign In isn’t available on this simulator. Try on a real device or use Google."
                } else {
                    errorMessage = "Sign in failed (\(underlyingNSError.domain) \(underlyingNSError.code))."
                }
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            }
            return
        }

        errorMessage = error.localizedDescription
    }
}
