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
    private let screenTimeService = ScreenTimeService.shared
    private let onboardingService = OnboardingService.shared
    private let logger = LoggerService.shared
    private let keychainService = KeychainService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Deep link handling
    private let deepLinkHandler = DeepLinkHandler.shared
    
    enum AppFlow {
        case loading
        case onboarding
        case screenTimeOnboarding
        case auth
        case postAuthOnboarding
        case main
    }
    
    init() {
        setupAuthObserver()
        setupDeepLinkObserver()
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
    
    private func setupDeepLinkObserver() {
        deepLinkHandler.$pendingDeepLink
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deepLink in
                guard let deepLink = deepLink else { return }
                self?.handleDeepLink(deepLink)
            }
            .store(in: &cancellables)
    }
    
    private func determineInitialFlow() {
        #if DEBUG && targetEnvironment(simulator)
        let shouldReset = ProcessInfo.processInfo.arguments.contains("-resetOnboarding")
            || ProcessInfo.processInfo.environment["UITESTING"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if shouldReset {
            UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.hasSeenOnboarding)
            UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.hasCompletedOnboarding)
            UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.currentUserId)
            try? keychainService.delete(forKey: AppConfig.UserDefaultsKeys.accessToken)
            try? keychainService.delete(forKey: AppConfig.UserDefaultsKeys.refreshToken)
            logger.logInfo("Routing: cleared onboarding + auth session (DEBUG reset)", category: "Navigation")
        }
        #endif

        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: AppConfig.UserDefaultsKeys.hasSeenOnboarding)
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: AppConfig.UserDefaultsKeys.hasCompletedOnboarding)
        let isAuthenticated = authViewModel.currentUser != nil

        logger.logInfo(
            "Routing: seen=\(hasSeenOnboarding) completed=\(hasCompletedOnboarding) authed=\(isAuthenticated)",
            category: "Navigation"
        )

        if !hasCompletedOnboarding {
            startOnboardingFlow()
            return
        }

        if isAuthenticated {
            routeAfterAuth()
            return
        }

        startAuthFlow()
    }
    
    private func handleAuthStateChange(user: User?) {
        if user != nil && currentFlow != .main {
            // User just signed in
            if authViewModel.needsUsernameSetup {
                // Stay in auth flow for username setup
                return
            }
            routeAfterAuth()
        } else if user == nil && currentFlow == .main {
            // User signed out
            startAuthFlow()
        }
    }
    
    // MARK: - Flow Management
    
    func startOnboardingFlow() {
        currentFlow = .onboarding
        onboardingFlow = OnboardingFlow(parentCoordinator: self, authViewModel: authViewModel)
        onboardingFlow?.start()
    }
    
    func startScreenTimeOnboardingFlow() {
        currentFlow = .screenTimeOnboarding
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

    private func routeAfterAuth() {
        Task { @MainActor in
            let state = await onboardingService.loadState()
            if state.isComplete {
                startMainFlow()
            } else {
                currentFlow = .postAuthOnboarding
            }
        }
    }
    
    func handleScreenTimeOnboardingComplete() {
        // After Screen Time onboarding, check auth state
        if authViewModel.currentUser != nil {
            startMainFlow()
        } else {
            startAuthFlow()
        }
    }
    
    func handleAuthenticationSuccess() {
        // Called when auth flow completes successfully
        if !authViewModel.needsUsernameSetup {
            startMainFlow()
        }
    }
    
    func handleOnboardingComplete() {
        // Called when onboarding completes
        if authViewModel.currentUser != nil {
            startMainFlow()
        } else {
            startAuthFlow()
        }
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(_ deepLink: DeepLink) {
        // Only handle deep links if user is authenticated and in main flow
        guard authViewModel.currentUser != nil else {
            // Store deep link to handle after authentication
            return
        }
        
        // Ensure we're in the main flow
        if currentFlow != .main {
            startMainFlow()
            // Wait a moment for flow to initialize, then handle deep link
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.handleDeepLink(deepLink)
            }
            return
        }
        
        guard let mainTabFlow = mainTabFlow else { return }
        
        switch deepLink {
        case .home:
            // Already in main flow, no navigation needed
            // Clear any pending deep link context
            AppGroupStorage.shared.clearPendingDeepLinkContext()
            deepLinkHandler.clearPendingDeepLink()
            break
            
        case .unlockRequest:
            // V1: unlock requests are not user-facing. Clear and ignore.
            deepLinkHandler.clearPendingDeepLink()
            AppGroupStorage.shared.clearPendingDeepLinkContext()
            
        case .messagePartner:
            // V1: partner messaging is not available. Clear and ignore.
            deepLinkHandler.clearPendingDeepLink()
            AppGroupStorage.shared.clearPendingDeepLinkContext()

        case .invite:
            // V1: invite attribution is handled at signup. Clear pending link.
            deepLinkHandler.clearPendingDeepLink()
            AppGroupStorage.shared.clearPendingDeepLinkContext()

        case .session(let sessionId):
            // Navigate to session detail if session ID is valid
            if let uuid = UUID(uuidString: sessionId) {
                Task {
                    do {
                        // Try to get active session
                        if let activeSession = try await SessionService.shared.getActiveSession(),
                           activeSession.id == uuid {
                            await MainActor.run {
                                mainTabFlow.navigateToActiveSession(session: activeSession)
                                deepLinkHandler.clearPendingDeepLink()
                            }
                        } else {
                            await MainActor.run {
                                deepLinkHandler.clearPendingDeepLink()
                            }
                        }
                    } catch {
                        await MainActor.run {
                            deepLinkHandler.clearPendingDeepLink()
                        }
                    }
                }
            } else {
                deepLinkHandler.clearPendingDeepLink()
            }
            
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
            OnboardingRootView(onComplete: { [weak self] in
                self?.handleOnboardingComplete()
            })
            .withGlobalToasts()
            
        case .screenTimeOnboarding:
            ScreenTimeOnboardingFlowView(onComplete: { [weak self] in
                self?.handleScreenTimeOnboardingComplete()
            })
            .withGlobalToasts()
            
        case .auth:
            if let flow = authFlow {
                flow.rootView
                    .withGlobalToasts()
            }

        case .postAuthOnboarding:
            PostAuthOnboardingFlowView(onComplete: { [weak self] in
                self?.startMainFlow()
            })
            .withGlobalToasts()
            
        case .main:
            if let flow = mainTabFlow {
                flow.rootView
                    .withGlobalToasts()
            }
        }
    }
}
