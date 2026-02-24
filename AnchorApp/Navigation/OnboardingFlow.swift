import SwiftUI
import Combine

/// Coordinator for the onboarding flow
@MainActor
class OnboardingFlow: Coordinator {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreenCover: FullScreenCoverDestination?
    
    private let onboardingViewModel = OnboardingViewModel()
    private let authViewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    weak var parentCoordinator: AppCoordinator?
    
    init(parentCoordinator: AppCoordinator? = nil, authViewModel: AuthViewModel = AuthViewModel()) {
        self.parentCoordinator = parentCoordinator
        self.authViewModel = authViewModel
        setupOnboardingObserver()
    }
    
    func start() {
        // Onboarding flow starts with the main onboarding view
        // The view itself handles internal navigation
    }
    
    private func setupOnboardingObserver() {
        // Observe when onboarding is completed
        onboardingViewModel.$hasCompletedOnboarding
            .dropFirst() // Skip initial value
            .filter { $0 == true }
            .sink { [weak self] _ in
                self?.parentCoordinator?.handleOnboardingComplete()
            }
            .store(in: &cancellables)
    }
    
    func completeOnboarding() {
        onboardingViewModel.completeOnboarding()
        // Navigation back to auth/main flow is handled by parent coordinator
    }
    
    var rootView: some View {
        OnboardingView()
            .environmentObject(onboardingViewModel)
            .environmentObject(authViewModel)
    }
}
