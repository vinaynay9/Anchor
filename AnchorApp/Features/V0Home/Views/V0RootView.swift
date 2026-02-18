import SwiftUI
import Shared

struct V0RootView: View {
    private enum RootState {
        case loading
        case auth
        case onboarding
        case home
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var rootState: RootState = .loading
    @State private var refreshToken = UUID()

    private let storage = AppGroupStorage.shared

    var body: some View {
        Group {
            switch rootState {
            case .loading:
                ProgressView("Loading...")
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .auth:
                V0AuthEntryView {
                    Task { await determineRoot() }
                }

            case .onboarding:
                V0OnboardingRootView {
                    V0UnlockPolicyService.shared.applyBaselineLocks()
                    Task { await determineRoot() }
                }

            case .home:
                V0HomeView()
            }
        }
        .applyV0Theme()
        .onAppear {
            Task { await determineRoot() }
            V0DailyResetService.shared.runIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                V0DailyResetService.shared.runIfNeeded()
                Task { await determineRoot() }
            }
        }
        .onReceive(storage.updatesPublisher) { _ in
            refreshToken = UUID()
        }
        .id(refreshToken)
    }

    @MainActor
    private func determineRoot() async {
        let isSignedIn = await isAuthenticated()
        if !isSignedIn {
            rootState = .auth
            return
        }

        if !isV0Configured() {
            rootState = .onboarding
            return
        }

        rootState = .home
    }

    private func isAuthenticated() async -> Bool {
        do {
            let user = try await AuthService.shared.currentUser()
            return user != nil
        } catch {
            return false
        }
    }

    private func isV0Configured() -> Bool {
        let goals = storage.getV0Goals()
        let config = storage.getV0UnlockConfig()
        let selection = storage.getV0AppSelection()
        let hasSelection = !selection.blockedApplications.isEmpty || !selection.blockedCategories.isEmpty
        return !goals.isEmpty && config != nil && hasSelection
    }
}
