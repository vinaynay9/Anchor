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
    private var cancellables = Set<AnyCancellable>()
    
    // Deep link handling
    private let deepLinkHandler = DeepLinkHandler.shared
    
    enum AppFlow {
        case loading
        case onboarding
        case screenTimeOnboarding
        case auth
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
        // Check Screen Time authorization
        // If user has completed onboarding but doesn't have Screen Time access, show Screen Time onboarding
        if !screenTimeService.isAuthorized() {
            startScreenTimeOnboardingFlow()
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
        onboardingFlow?.completeOnboarding()
        
        // Determine next flow based on auth state
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
            
        case .unlockRequest(let id):
            // Navigate to unlock request detail if ID is provided
            if let requestId = id, let uuid = UUID(uuidString: requestId) {
                // Try to load the request and navigate
                Task {
                    do {
                        let requests = try await UnlockRequestService.shared.getPendingUnlockRequests()
                        if let request = requests.first(where: { $0.id == uuid }) {
                            await MainActor.run {
                                mainTabFlow.navigateToUnlockRequestDetail(request: request)
                                deepLinkHandler.clearPendingDeepLink()
                            }
                        } else {
                            // If request not found, check context from AppGroupStorage
                            let context = AppGroupStorage.shared.getPendingDeepLinkContext()
                            if let contextRequestId = context["unlockRequestId"],
                               let contextUUID = UUID(uuidString: contextRequestId),
                               let contextRequest = requests.first(where: { $0.id == contextUUID }) {
                                await MainActor.run {
                                    mainTabFlow.navigateToUnlockRequestDetail(request: contextRequest)
                                    deepLinkHandler.clearPendingDeepLink()
                                    AppGroupStorage.shared.clearPendingDeepLinkContext()
                                }
                            } else {
                                await MainActor.run {
                                    deepLinkHandler.clearPendingDeepLink()
                                    AppGroupStorage.shared.clearPendingDeepLinkContext()
                                }
                            }
                        }
                    } catch {
                        await MainActor.run {
                            deepLinkHandler.clearPendingDeepLink()
                            AppGroupStorage.shared.clearPendingDeepLinkContext()
                        }
                    }
                }
            } else {
                // No ID provided, just navigate to friends tab (where unlock requests are shown)
                deepLinkHandler.clearPendingDeepLink()
            }
            
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
            
        case .messagePartner:
            // Navigate to messaging screen (if implemented)
            // For now, just navigate to friends tab
            deepLinkHandler.clearPendingDeepLink()
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
            
        case .main:
            if let flow = mainTabFlow {
                flow.rootView
                    .withGlobalToasts()
            }
        }
    }
}
