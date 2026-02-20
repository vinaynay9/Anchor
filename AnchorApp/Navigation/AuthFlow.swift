import SwiftUI

/// Coordinator for the authentication flow
@MainActor
class AuthFlow: Coordinator, SheetPresenting {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    
    private let authViewModel = AuthViewModel()
    weak var parentCoordinator: AppCoordinator?
    
    init(parentCoordinator: AppCoordinator? = nil) {
        self.parentCoordinator = parentCoordinator
    }
    
    func start() {
        // Auth flow starts with sign in options
        // Navigation is handled by the view based on auth state
    }
    
    func navigateToUsernameSetup() {
        // Username setup is shown conditionally in AuthRootView
        // No explicit navigation needed
    }
    
    func handleAuthenticationSuccess() {
        // Notify parent coordinator that authentication succeeded
        parentCoordinator?.handleAuthenticationSuccess()
    }
    
    var rootView: some View {
        AuthRootView()
            .environmentObject(authViewModel)
            .onChange(of: authViewModel.currentUser) { [weak self] newValue in
                guard let self = self else { return }
                if newValue != nil && !self.authViewModel.needsUsernameSetup {
                    self.handleAuthenticationSuccess()
                }
            }
    }
}
