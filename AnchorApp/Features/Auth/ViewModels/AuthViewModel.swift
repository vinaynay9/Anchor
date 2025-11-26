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
                    self.errorMessage = error.localizedDescription
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
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.needsUsernameSetup = false
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
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
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.needsUsernameSetup = false
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func completeUsernameSetup(_ username: String) {
        guard let currentUser = currentUser else {
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
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

