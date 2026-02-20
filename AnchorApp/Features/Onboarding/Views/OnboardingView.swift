import SwiftUI
import Shared

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var goalsViewModel = GoalViewModel()
    @State private var currentStep: OnboardingStep = .welcome
    @State private var showGoalCreation = false
    @State private var displayName: String = ""
    @State private var birthMonth: Int = 1
    @State private var birthDay: Int = 1
    @State private var timezone: String = TimeZone.current.identifier
    
    enum OnboardingStep {
        case welcome
        case description
        case signIn
        case profile
        case permissions
        case goalsExplanation
        case goalCreation
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeOnboardingPage(onContinue: {
                        animate {
                            currentStep = .description
                        }
                    })
                    
                case .description:
                    DescriptionSlidesPage(onContinue: {
                        animate {
                            currentStep = .signIn
                        }
                    })
                    
                case .signIn:
                    SignInOnboardingPage(
                        authViewModel: authViewModel,
                        onSignIn: {
                            animate {
                                currentStep = .profile
                            }
                        },
                        onLogin: {
                            // Handle login for existing users
                            animate {
                                currentStep = .profile
                            }
                        }
                    )

                case .profile:
                    ProfileOnboardingPage(
                        displayName: $displayName,
                        birthMonth: $birthMonth,
                        birthDay: $birthDay,
                        timezone: $timezone,
                        onContinue: {
                            AppGroupStorage.shared.setProfile(
                                displayName: displayName,
                                birthMonth: birthMonth,
                                birthDay: birthDay,
                                timezone: timezone
                            )
                            Task {
                                await AnalyticsIngestService.shared.sendDailyProfileIfConfigured()
                            }
                            animate {
                                currentStep = .permissions
                            }
                        }
                    )
                    
                case .permissions:
                    ScreenTimeOnboardingFlowView(onComplete: {
                        animate {
                            currentStep = .goalsExplanation
                        }
                    })
                    
                case .goalsExplanation:
                    GoalsExplanationView(onContinue: {
                        animate {
                            currentStep = .goalCreation
                        }
                    })
                    
                case .goalCreation:
                    GoalCreationOnboardingPage(
                        goalViewModel: goalsViewModel,
                        onContinue: {
                            animate {
                                viewModel.completeOnboarding()
                            }
                        }
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeOut(duration: 0.25), value: currentStep)
        }
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

// MARK: - Welcome Page
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: Theme.padding * 2) {
            Spacer()
            
            // Gradient background circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.textTertiary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .opacity(0.6)
                
                // App icon/logo
                Image("Anchor_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
            }
            .padding(.bottom, Theme.padding * 3)
            
            VStack(spacing: Theme.spacing * 2) {
                Text("Anchor your day")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Lock apps. Set goals. Stay Anchored.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.padding * 2)
            }
            
            Spacer()
        }
        .padding(Theme.padding * 2)
    }
}

// MARK: - App Blocking Page
struct AppBlockingPage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.padding * 2) {
            Spacer()
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "lock.shield.fill")
                    .font(AppTypography.screenTitle).fontWeight(.light)
                    .foregroundColor(AppColors.accent)
            }
            .padding(.bottom, Theme.padding * 3)
            
            VStack(spacing: Theme.spacing * 2) {
                Text("Stay Anchored with app blocking")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Lock selected apps until your goals are complete.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.padding * 2)
            }
            
            Spacer()
        }
        .padding(Theme.padding * 2)
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
