import SwiftUI
import Combine
import Shared

/// Main app coordinator that manages all navigation flows.
@MainActor
class AppCoordinator: ObservableObject {

    // MARK: - Flow State
    @Published var currentFlow: AppFlow = .loading

    // MARK: - Child Coordinators
    @Published private(set) var onboardingFlow: OnboardingFlow?
    @Published private(set) var authFlow: AuthFlow?
    @Published private(set) var mainTabFlow: MainTabFlow?

    // MARK: - Services
    private let authViewModel    = AuthViewModel()
    private let screenTimeService = ScreenTimeService.shared
    private let onboardingService = OnboardingService.shared
    private let logger           = LoggerService.shared
    private let keychainService  = KeychainService.shared
    private var cancellables     = Set<AnyCancellable>()

    // MARK: - Social Auth Prefill
    // Stored after a successful social sign-in so ProfileSetupView can pre-fill
    // first/last name from the provider's profile without needing a backend round-trip.
    private var pendingAuthFirstName: String?
    private var pendingAuthLastName:  String?

    // MARK: - Deep Link
    private let deepLinkHandler = DeepLinkHandler.shared

    // MARK: - Flow Enum

    enum AppFlow {
        case loading
        case onboarding
        case screenTimeOnboarding
        case auth
        /// Shown after social sign-in when personal info hasn't been set up yet.
        case profileSetup
        case postAuthOnboarding
        case main
    }

    // MARK: - Init

    init() {
        setupAuthObserver()
        setupDeepLinkObserver()
        determineInitialFlow()
    }

    // MARK: - Observers

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
                guard let deepLink else { return }
                self?.handleDeepLink(deepLink)
            }
            .store(in: &cancellables)
    }

    // MARK: - Initial Routing

    private func determineInitialFlow() {
#if DEBUG && targetEnvironment(simulator)
        let shouldReset = ProcessInfo.processInfo.arguments.contains("-resetOnboarding")
            || ProcessInfo.processInfo.environment["UITESTING"]              == "1"
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

        let hasCompletedOnboarding = UserDefaults.standard.bool(
            forKey: AppConfig.UserDefaultsKeys.hasCompletedOnboarding
        )

        // For the Supabase migration period, treat a stored userId OR a live User
        // object as "authenticated".  Once Supabase is wired up, authViewModel.currentUser
        // will be non-nil on every warm start and this fallback can be removed.
        let hasCachedUserId = UserDefaults.standard.string(
            forKey: AppConfig.UserDefaultsKeys.currentUserId
        ) != nil
        let isAuthenticated = authViewModel.currentUser != nil || hasCachedUserId

        logger.logInfo(
            "Routing: onboarded=\(hasCompletedOnboarding) authed=\(isAuthenticated)",
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

    // MARK: - Auth State Change (Combine observer)

    private func handleAuthStateChange(user: User?) {
        if let user, currentFlow != .main {
            logger.logInfo("Routing: auth state changed — user signed in (\(user.id))", category: "Navigation")
            // Username setup is no longer part of the flow (replaced by ProfileSetupView).
            routeAfterAuth()
        } else if user == nil, currentFlow == .main {
            logger.logInfo("Routing: auth state changed — user signed out", category: "Navigation")
            startAuthFlow()
        }
    }

    // MARK: - Flow Management

    func startOnboardingFlow() {
        currentFlow    = .onboarding
        onboardingFlow = OnboardingFlow(parentCoordinator: self, authViewModel: authViewModel)
        onboardingFlow?.start()
    }

    func startScreenTimeOnboardingFlow() {
        currentFlow = .screenTimeOnboarding
    }

    func startAuthFlow() {
        currentFlow = .auth
        authFlow    = AuthFlow(parentCoordinator: self)
        authFlow?.start()
    }

    func startMainFlow() {
        currentFlow  = .main
        mainTabFlow  = MainTabFlow()
        mainTabFlow?.start()
    }

    // MARK: - Social Auth Entry Point
    // Called by AuthFlow when SocialAuthView delivers a credential.

    func handleSocialAuthSuccess(credential: SocialAuthCredential) {
        logger.logInfo(
            "Social auth success — provider: \(credential.provider == .apple ? "Apple" : "Google")",
            category: "Navigation"
        )

        // Cache name for ProfileSetupView pre-fill.
        pendingAuthFirstName = credential.firstName
        pendingAuthLastName  = credential.lastName

        // Store a local user ID so subsequent cold-starts route correctly
        // (past auth screen) during the Supabase migration period.
        // This will be replaced by the Supabase session userId once migrated.
        if UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId) == nil {
            UserDefaults.standard.set(
                UUID().uuidString,
                forKey: AppConfig.UserDefaultsKeys.currentUserId
            )
        }

        // Store identity token for future backend calls.
        try? keychainService.save(
            credential.identityToken,
            forKey: AppConfig.UserDefaultsKeys.accessToken
        )
        if let code = credential.authorizationCode {
            try? keychainService.save(code, forKey: AppConfig.UserDefaultsKeys.refreshToken)
        }

        // TODO: [Supabase Migration] Exchange credential with Supabase here:
        // let session = try await SupabaseClient.shared.auth.signInWithIdToken(
        //     credentials: OpenIDConnectCredentials(
        //         provider: credential.provider == .apple ? .apple : .google,
        //         idToken:  credential.identityToken,
        //         nonce:    currentNonce       // raw nonce, not hashed
        //     )
        // )
        // let anchorUser = session.user.toAnchorUser()
        // authViewModel.handleAuthenticatedUser(anchorUser)

        routeAfterSocialAuth()
    }

    // MARK: - Post-Auth Routing

    /// Routing for social sign-ins — checks personal info before deciding next step.
    private func routeAfterSocialAuth() {
        Task { @MainActor in
            let state = await onboardingService.loadState()

            if state.isComplete {
                logger.logInfo("Routing: onboarding complete → main", category: "Navigation")
                startMainFlow()
            } else if AppGroupStorage.shared.getPersonalInfo() == nil {
                logger.logInfo("Routing: no personal info → profileSetup", category: "Navigation")
                currentFlow = .profileSetup
            } else {
                logger.logInfo("Routing: personal info set → postAuthOnboarding", category: "Navigation")
                currentFlow = .postAuthOnboarding
            }
        }
    }

    /// Routing used by the Combine observer (existing User session restored on launch).
    private func routeAfterAuth() {
        Task { @MainActor in
            let state = await onboardingService.loadState()

            if state.isComplete {
                logger.logInfo("Routing: onboarding complete → main", category: "Navigation")
                startMainFlow()
            } else if AppGroupStorage.shared.getPersonalInfo() == nil {
                logger.logInfo("Routing: no personal info → profileSetup", category: "Navigation")
                currentFlow = .profileSetup
            } else {
                logger.logInfo("Routing: personal info set → postAuthOnboarding", category: "Navigation")
                currentFlow = .postAuthOnboarding
            }
        }
    }

    // MARK: - Coordinator Callbacks

    func handleScreenTimeOnboardingComplete() {
        if authViewModel.currentUser != nil {
            startMainFlow()
        } else {
            startAuthFlow()
        }
    }

    func handleAuthenticationSuccess() {
        routeAfterAuth()
    }

    func handleOnboardingComplete() {
        if authViewModel.currentUser != nil {
            routeAfterAuth()
        } else {
            startAuthFlow()
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ deepLink: DeepLink) {
        guard authViewModel.currentUser != nil else { return }

        if currentFlow != .main {
            startMainFlow()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.handleDeepLink(deepLink)
            }
            return
        }

        guard let mainTabFlow else { return }

        switch deepLink {
        case .home:
            AppGroupStorage.shared.clearPendingDeepLinkContext()
            deepLinkHandler.clearPendingDeepLink()

        case .unlockRequest, .messagePartner, .invite:
            deepLinkHandler.clearPendingDeepLink()
            AppGroupStorage.shared.clearPendingDeepLinkContext()

        case .session(let sessionId):
            guard let uuid = UUID(uuidString: sessionId) else {
                deepLinkHandler.clearPendingDeepLink()
                return
            }
            Task {
                do {
                    if let active = try await SessionService.shared.getActiveSession(),
                       active.id == uuid {
                        await MainActor.run {
                            mainTabFlow.navigateToActiveSession(session: active)
                            deepLinkHandler.clearPendingDeepLink()
                        }
                    } else {
                        await MainActor.run { deepLinkHandler.clearPendingDeepLink() }
                    }
                } catch {
                    await MainActor.run { deepLinkHandler.clearPendingDeepLink() }
                }
            }
        }
    }

    // MARK: - Root View

    @ViewBuilder
    var rootView: some View {
        switch currentFlow {
        case .loading:
            ProgressView("Loading…")
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

        case .profileSetup:
            ProfileSetupView(
                prefillFirstName: pendingAuthFirstName,
                prefillLastName:  pendingAuthLastName,
                onComplete: { [weak self] in
                    self?.logger.logInfo("Routing: profile setup complete → postAuthOnboarding", category: "Navigation")
                    self?.currentFlow = .postAuthOnboarding
                }
            )
            .withGlobalToasts()

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
