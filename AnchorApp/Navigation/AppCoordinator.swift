import SwiftUI
import Combine
import Shared

/// Main app coordinator that manages all navigation flows
@MainActor
class AppCoordinator: ObservableObject {
    // Current flow state
    @Published var currentFlow: AppFlow = .loading
    
    // Child coordinators
    @Published private(set) var onboardingFlow: OnboardingFlow?
    @Published private(set) var authFlow: AuthFlow?
    @Published private(set) var mainTabFlow: MainTabFlow?
    
    // Auth state management
    private let authViewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    enum AppFlow {
        case loading
        case onboarding
        case auth
        case main
    }
    
    init() {
        setupAuthObserver()
        determineInitialFlow()
    }
    
    private func setupAuthObserver() {
        authViewModel.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.handleAuthStateChange(user: user)
            }
            .store(in: &cancellables)
    }
    
    private func determineInitialFlow() {
        // Check if user needs onboarding
        let onboardingViewModel = OnboardingViewModel()
        if !onboardingViewModel.hasCompletedOnboarding {
            startOnboardingFlow()
            return
        }
        
        // Check auth state
        if authViewModel.currentUser != nil {
            startMainFlow()
        } else {
            startAuthFlow()
        }
    }
    
    private func handleAuthStateChange(user: User?) {
        if user != nil && currentFlow != .main {
            // User just signed in
            if authViewModel.needsUsernameSetup {
                // Stay in auth flow for username setup
                return
            }
            startMainFlow()
        } else if user == nil && currentFlow == .main {
            // User signed out
            startAuthFlow()
        }
    }
    
    // MARK: - Flow Management
    
    func startOnboardingFlow() {
        currentFlow = .onboarding
        onboardingFlow = OnboardingFlow(parentCoordinator: self)
        onboardingFlow?.start()
    }
    
    func startAuthFlow() {
        currentFlow = .auth
        authFlow = AuthFlow(parentCoordinator: self)
        authFlow?.start()
    }
    
    func startMainFlow() {
        currentFlow = .main
        mainTabFlow = MainTabFlow()
        mainTabFlow?.start()
    }
    
    func handleAuthenticationSuccess() {
        // Called when auth flow completes successfully
        if !authViewModel.needsUsernameSetup {
            startMainFlow()
        }
    }
    
    func handleOnboardingComplete() {
        // Called when onboarding completes
        onboardingFlow?.completeOnboarding()
        
        // Determine next flow based on auth state
        if authViewModel.currentUser != nil {
            startMainFlow()
        } else {
            startAuthFlow()
        }
    }
    
    // MARK: - Root View
    
    @ViewBuilder
    var rootView: some View {
        switch currentFlow {
        case .loading:
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .withGlobalToasts()
            
        case .onboarding:
            if let flow = onboardingFlow {
                flow.rootView
                    .withGlobalToasts()
            }
            
        case .auth:
            if let flow = authFlow {
                flow.rootView
                    .withGlobalToasts()
            }
            
        case .main:
            if let flow = mainTabFlow {
                flow.rootView
                    .withGlobalToasts()
            }
        }
    }
}

