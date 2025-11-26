import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let userService = UserService.shared
    private let authService = AuthService.shared
    
    func loadCurrentUser() {
        isLoading = true
        
        Task {
            do {
                let user = try await userService.getCurrentUser()
                await MainActor.run {
                    self.currentUser = user
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func signOut() {
        Task {
            try? await authService.signOut()
        }
    }
}

