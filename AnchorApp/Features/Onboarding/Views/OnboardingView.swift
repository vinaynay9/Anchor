import SwiftUI
import Shared

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var emailAuthViewModel = EmailAuthViewModel()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            Group {
                switch viewModel.currentStep {
                case .intro:
                    IntroOnboardingPage(onContinue: {
                        viewModel.markSeen()
                        animate { viewModel.advance(to: .what) }
                    })
                case .what:
                    WhatOnboardingPage(onContinue: {
                        animate { viewModel.advance(to: .why) }
                    })
                case .why:
                    WhyOnboardingPage(
                        onJoin: { animate { viewModel.advance(to: .signUp) } },
                        onSignIn: { animate { viewModel.advance(to: .signIn) } }
                    )
                case .signUp:
                    EmailSignUpView(viewModel: emailAuthViewModel) { user in
                        authViewModel.handleAuthenticatedUser(user)
                        viewModel.syncPersonalInfoIfAvailable(user: user)
                        animate { viewModel.advance(to: .personalInfo) }
                    }
                case .signIn:
                    EmailSignInView(viewModel: emailAuthViewModel) { user in
                        authViewModel.handleAuthenticatedUser(user)
                        viewModel.syncPersonalInfoIfAvailable(user: user)
                        if viewModel.isPersonalInfoComplete(user: user) {
                            animate { viewModel.advance(to: .goalsFlow) }
                        } else {
                            animate { viewModel.advance(to: .personalInfo) }
                        }
                    }
                case .personalInfo:
                    PersonalInfoView(onboardingViewModel: viewModel) {
                        animate { viewModel.advance(to: .goalsFlow) }
                    }
                case .goalsFlow:
                    PostAuthOnboardingFlowView(onComplete: {
                        viewModel.completeOnboarding()
                    })
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeOut(duration: 0.25), value: viewModel.currentStep)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func animate(_ animation: Animation = AppMotion.gentleSpring, delay: Double = 0, _ changes: @escaping () -> Void) {
        if reduceMotion {
            changes()
        } else {
            withAnimation(animation.delay(delay)) {
                changes()
            }
        }
    }
}

// MARK: - Intro
struct IntroOnboardingPage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacing4) {
            Spacer()

            Image("Anchor_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            VStack(spacing: Theme.spacing2) {
                Text("Hey, we’re Anchor")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.onboardingTitleText)
                    .multilineTextAlignment(.center)

                Text("Lock in your day with goals and real accountability.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingBodyText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }

            Button(action: onContinue) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacing3)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - What is Anchor
struct WhatOnboardingPage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacing4) {
            Spacer()

            VStack(spacing: Theme.spacing2) {
                Text("What is Anchor?")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.onboardingTitleText)

                Text("Anchor uses Screen Time to block apps until your goals are completed.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingBodyText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }

            Button(action: onContinue) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacing3)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Why Anchor
struct WhyOnboardingPage: View {
    let onJoin: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacing4) {
            Spacer()

            VStack(spacing: Theme.spacing2) {
                Text("Why use Anchor?")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.onboardingTitleText)

                Text("Stay accountable, finish what matters, and earn your screen time back.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingBodyText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }

            VStack(spacing: Theme.spacing2) {
                Button(action: onJoin) {
                    Text("Join")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(action: onSignIn) {
                    Text("Sign in")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, Theme.spacing3)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
