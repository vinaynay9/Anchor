import SwiftUI

// MARK: - Welcome Page
struct WelcomeOnboardingPage: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.spacing4) {
            Spacer()
            
            // Logo with gradient
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
                
                Image(systemName: "anchor.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(AppColors.anchorAccent)
            }
            .padding(.bottom, Theme.spacing3)
            
            VStack(spacing: Theme.spacing2) {
                Text("Welcome to Anchor")
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Your personal accountability partner for staying focused and productive")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacing3)
            .padding(.bottom, Theme.spacing3)
        }
    }
}

// MARK: - Description Slides
struct DescriptionSlidesPage: View {
    @State private var currentSlide = 0
    let onContinue: () -> Void
    
    private let slides = [
        SlideData(
            icon: "lock.shield.fill",
            title: "Stay Focused",
            description: "Block distracting apps during your focus sessions and stay on track with your goals"
        ),
        SlideData(
            icon: "person.2.fill",
            title: "Stay Accountable",
            description: "Connect with friends who help you stay accountable and unlock your apps when you need them"
        ),
        SlideData(
            icon: "target",
            title: "Build Habits",
            description: "Set daily goals and complete them to unlock your apps, building better habits every day"
        )
    ]
    
    var body: some View {
        VStack(spacing: Theme.spacing4) {
            TabView(selection: $currentSlide) {
                ForEach(0..<slides.count, id: \.self) { index in
                    SlideView(slide: slides[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(Theme.springAnimation, value: currentSlide)
            
            // Page dots
            HStack(spacing: Theme.spacing) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentSlide ? AppColors.anchorAccent : AppColors.anchorAccent.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(Theme.springAnimationFast, value: currentSlide)
                }
            }
            .padding(.bottom, Theme.spacing)
            
            Button(action: {
                if currentSlide < slides.count - 1 {
                    withAnimation(Theme.springAnimation) {
                        currentSlide += 1
                    }
                } else {
                    onContinue()
                }
            }) {
                Text(currentSlide < slides.count - 1 ? "Next" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacing3)
            .padding(.bottom, Theme.spacing3)
        }
    }
}

struct SlideData {
    let icon: String
    let title: String
    let description: String
}

struct SlideView: View {
    let slide: SlideData
    
    var body: some View {
        VStack(spacing: Theme.spacing3) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 120, height: 120)
                
                Image(systemName: slide.icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(AppColors.anchorAccent)
            }
            .padding(.bottom, Theme.spacing3)
            
            VStack(spacing: Theme.spacing2) {
                Text(slide.title)
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(slide.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }
            
            Spacer()
        }
        .padding(Theme.spacing3)
    }
}

// MARK: - Sign In Page
struct SignInOnboardingPage: View {
    @ObservedObject var authViewModel: AuthViewModel
    let onSignIn: () -> Void
    let onLogin: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.spacing4) {
            Spacer()
            
            VStack(spacing: Theme.spacing2) {
                Text("Sign In")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Create an account or sign in to continue")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }
            
            Spacer()
            
            VStack(spacing: Theme.spacing2) {
                // Apple Sign In
                Button(action: {
                    Task {
                        do {
                            _ = try await authViewModel.signInWithApple()
                            onSignIn()
                        } catch {
                            // Error handled by viewModel
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.system(size: 18))
                        Text("Continue with Apple")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(authViewModel.isLoading)
                
                // Google Sign In
                Button(action: {
                    Task {
                        do {
                            _ = try await authViewModel.signInWithGoogle()
                            onSignIn()
                        } catch {
                            // Error handled by viewModel
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                        Text("Continue with Google")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(authViewModel.isLoading)
                
                // Login button for existing users
                Button(action: onLogin) {
                    Text("Already have an account? Sign In")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.anchorAccent)
                }
                .buttonStyle(GhostButtonStyle())
                .padding(.top, Theme.spacing)
            }
            .padding(.horizontal, Theme.spacing3)
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.horizontal, Theme.spacing3)
            }
            
            Spacer()
        }
    }
}

// MARK: - Permissions Explanation Page
struct PermissionsExplanationPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing3) {
                VStack(spacing: Theme.spacing2) {
                    Text("Permissions")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Anchor needs these permissions to work properly")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.spacing3)
                .padding(.horizontal, Theme.spacing2)
                
                VStack(spacing: Theme.spacing2) {
                    PermissionExplanationItem(
                        icon: "lock.shield.fill",
                        title: "Screen Time",
                        description: "Required to block apps during focus sessions"
                    )
                    
                    PermissionExplanationItem(
                        icon: "camera.fill",
                        title: "Camera",
                        description: "For taking photo proof when requesting unlocks"
                    )
                    
                    PermissionExplanationItem(
                        icon: "mic.fill",
                        title: "Microphone",
                        description: "For voice notes and witness confirmations"
                    )
                    
                    PermissionExplanationItem(
                        icon: "person.crop.circle.fill",
                        title: "Contacts",
                        description: "To find and add accountability friends"
                    )
                }
                .padding(.horizontal, Theme.spacing2)
                
                Button(action: {
                    viewModel.requestPermissions()
                    onContinue()
                }) {
                    Text("Grant Permissions")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.spacing3)
                .padding(.top, Theme.spacing2)
                .padding(.bottom, Theme.spacing3)
            }
        }
    }
}

struct PermissionExplanationItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Theme.spacing2) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppColors.anchorAccent)
            }
            
            VStack(alignment: .leading, spacing: Theme.smallSpacing) {
                Text(title)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(Theme.spacing2)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

// MARK: - Goal Creation Onboarding Page
struct GoalCreationOnboardingPage: View {
    @ObservedObject var goalViewModel: GoalViewModel
    @State private var showGoalCreation = false
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.spacing3) {
            Text("Set Your First Goal")
                .font(AppTypography.largeTitle)
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, Theme.spacing3)
            
            Text("Create a daily habit to stay focused")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, Theme.spacing3)
            
            Spacer()
            
            if goalViewModel.getTotalCount() == 0 {
                Button(action: {
                    showGoalCreation = true
                }) {
                    Text("Add Your First Goal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.spacing3)
            } else {
                VStack(spacing: Theme.spacing2) {
                    Text("Great! You've set \(goalViewModel.getTotalCount()) goal(s)")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Button(action: onContinue) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, Theme.spacing3)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showGoalCreation) {
            NavigationStack {
                GoalCreationView()
            }
        }
    }
}

// MARK: - Friend Selection Onboarding Page
struct FriendSelectionOnboardingPage: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.spacing3) {
            Text("Add Accountability Friends")
                .font(AppTypography.largeTitle)
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, Theme.spacing3)
            
            Text("You can add friends later in settings")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, Theme.spacing3)
            
            Spacer()
            
            Button(action: onComplete) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.spacing3)
            .padding(.bottom, Theme.spacing3)
        }
    }
}
