import SwiftUI
import Combine

enum AuthState {
    case signedOut
    case loading
    case signedIn(User)
}

class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .signedOut
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    private let userService = UserService.shared
    
    init() {
        checkAuthState()
    }
    
    private func checkAuthState() {
        // TODO: Check if user is already signed in
        // Check for stored tokens and validate
        authState = .signedOut
    }
    
    func signIn(with provider: AuthProvider) {
        authState = .loading
        errorMessage = nil
        
        Task {
            do {
                let (token, user) = try await authService.signIn(with: provider)
                await MainActor.run {
                    self.authState = .signedIn(user)
                }
            } catch {
                await MainActor.run {
                    self.authState = .signedOut
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signOut() {
        Task {
            do {
                try await authService.signOut()
                await MainActor.run {
                    self.authState = .signedOut
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

