import SwiftUI
import Shared

struct LegacyOnboardingRootView: View {
    @StateObject private var state = OnboardingState()
    @StateObject private var authViewModel = AuthViewModel()
    @Namespace private var heroNamespace
    @State private var step: Step = .intro
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Step: Int, CaseIterable {
        case intro = 0
        case signIn
        case profile
        case permissions
        case complete
    }

    var body: some View {
        ZStack {
            AnchorTheme.background.ignoresSafeArea()

            VStack(spacing: AnchorTheme.Spacing.lg) {
                progressBar

                ZStack {
                    switch step {
                    case .intro:
                        IntroView(namespace: heroNamespace) {
                            goTo(.signIn)
                        }
                        .transition(viewTransition)
                    case .signIn:
                        SignInView(authViewModel: authViewModel) {
                            goTo(.profile)
                        }
                        .transition(viewTransition)
                    case .profile:
                        ProfileView { name, month, day, timezone in
                            AppGroupStorage.shared.setProfile(
                                displayName: name,
                                birthMonth: month,
                                birthDay: day,
                                timezone: timezone
                            )
                            state.markProfileComplete()
                            Task {
                                await AnalyticsIngestService.shared.sendDailyProfileIfConfigured()
                            }
                            goTo(.permissions)
                        }
                        .transition(viewTransition)
                    case .permissions:
                        PermissionsView(state: state) {
                            goTo(.complete)
                        }
                        .transition(viewTransition)
                    case .complete:
                        OnboardingCompleteView {
                            state.hasCompletedOnboarding = true
                        }
                        .transition(viewTransition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, AnchorTheme.Spacing.lg)
            .padding(.top, AnchorTheme.Spacing.lg)
            .padding(.bottom, AnchorTheme.Spacing.xl)
        }
        .onReceive(authViewModel.$currentUser) { user in
            state.isSignedIn = (user != nil)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
    }

    private var progressBar: some View {
        HStack(spacing: AnchorTheme.Spacing.xs) {
            ForEach(Step.allCases, id: \.rawValue) { item in
                Capsule()
                    .fill(item.rawValue <= step.rawValue ? AnchorTheme.accent : AnchorTheme.cardBackground)
                    .frame(height: 6)
                    .animation(AppMotion.animation(AppMotion.gentleSpring, reduceMotion: reduceMotion), value: step)
            }
        }
    }

    private var viewTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private func goTo(_ next: Step) {
        if reduceMotion {
            step = next
        } else {
            withAnimation(AppMotion.gentleSpring) {
                step = next
            }
        }
    }
}
