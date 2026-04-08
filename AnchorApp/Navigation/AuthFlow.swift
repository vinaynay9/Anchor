import SwiftUI

/// Coordinator for the authentication flow.
/// Root view is now SocialAuthView — email/password auth has been removed.
@MainActor
class AuthFlow: Coordinator, SheetPresenting {
    @Published var path             = NavigationPath()
    @Published var presentedSheet: SheetDestination?

    weak var parentCoordinator: AppCoordinator?

    init(parentCoordinator: AppCoordinator? = nil) {
        self.parentCoordinator = parentCoordinator
    }

    func start() {
        // Flow is driven entirely by SocialAuthView callbacks — no internal state needed.
    }

    // MARK: - Root View

    var rootView: some View {
        SocialAuthView { [weak self] credential in
            // Deliver the credential to the coordinator; it will route to profileSetup.
            self?.parentCoordinator?.handleSocialAuthSuccess(credential: credential)
        }
    }
}
