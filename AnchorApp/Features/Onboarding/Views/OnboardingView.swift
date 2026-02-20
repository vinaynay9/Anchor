import SwiftUI
import Shared

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var goalsViewModel = GoalViewModel()
    @State private var currentStep: OnboardingStep = .welcome
    @State private var showGoalCreation = false
    @State private var showFriendSelection = false
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
        case friendSelection
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeOnboardingPage(onContinue: {
                        withAnimation(Theme.springAnimation) {
                            currentStep = .description
                        }
                    })
                    
                case .description:
                    DescriptionSlidesPage(onContinue: {
                        withAnimation(Theme.springAnimation) {
                            currentStep = .signIn
                        }
                    })
                    
                case .signIn:
                    SignInOnboardingPage(
                        authViewModel: authViewModel,
                        onSignIn: {
                            withAnimation(Theme.springAnimation) {
                                currentStep = .profile
                            }
                        },
                        onLogin: {
                            // Handle login for existing users
                            withAnimation(Theme.springAnimation) {
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
                            withAnimation(Theme.springAnimation) {
                                currentStep = .permissions
                            }
                        }
                    )
                    
                case .permissions:
                    ScreenTimeOnboardingFlowView(onComplete: {
                        withAnimation(Theme.springAnimation) {
                            currentStep = .goalsExplanation
                        }
                    })
                    
                case .goalsExplanation:
                    GoalsExplanationView(onContinue: {
                        withAnimation(Theme.springAnimation) {
                            currentStep = .goalCreation
                        }
                    })
                    
                case .goalCreation:
                    GoalCreationOnboardingPage(
                        goalViewModel: goalsViewModel,
                        onContinue: {
                            withAnimation(Theme.springAnimation) {
                                currentStep = .friendSelection
                            }
                        }
                    )
                    
                case .friendSelection:
                    FriendSelectionOnboardingPage(
                        onComplete: {
                            viewModel.completeOnboarding()
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
                            colors: [AppColors.anchorPrimary, AppColors.anchorLavender],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .opacity(0.6)
                
                // App icon placeholder or logo
                Image(systemName: "anchor.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(AppColors.anchorAccent)
            }
            .padding(.bottom, Theme.padding * 3)
            
            VStack(spacing: Theme.spacing * 2) {
                Text("Welcome to Anchor")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Your personal accountability partner for staying focused and productive")
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
    var body: some View {
        VStack(spacing: Theme.padding * 2) {
            Spacer()
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(AppColors.anchorAccent)
            }
            .padding(.bottom, Theme.padding * 3)
            
            VStack(spacing: Theme.spacing * 2) {
                Text("Stay focused with app blocking")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Block distracting apps during your focus sessions and stay on track with your goals")
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

// MARK: - Friends Accountability Page
struct FriendsAccountabilityPage: View {
    var body: some View {
        VStack(spacing: Theme.padding * 2) {
            Spacer()
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(AppColors.anchorAccent)
            }
            .padding(.bottom, Theme.padding * 3)
            
            VStack(spacing: Theme.spacing * 2) {
                Text("Stay accountable with friends")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Connect with friends who help you stay accountable and unlock your apps when you need them")
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
