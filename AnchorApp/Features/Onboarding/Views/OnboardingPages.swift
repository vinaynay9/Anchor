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
                            colors: [AppColors.primary, AppColors.textTertiary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .opacity(0.6)
                
                Image("Anchor_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
            }
            .padding(.bottom, Theme.spacing3)
            
            VStack(spacing: Theme.spacing2) {
                Text("Anchor your day")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.onboardingTitleText)
                
                Text("Lock apps. Set goals. Stay Anchored.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingBodyText)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Description Slides
struct DescriptionSlidesPage: View {
    @State private var currentSlide = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onContinue: () -> Void
    
    private let slides = [
        SlideData(
            icon: "lock.shield.fill",
            title: "Stay Anchored",
            description: "Lock selected apps until your goals are complete."
        ),
        SlideData(
            icon: "person.2.fill",
            title: "Anchor your day",
            description: "Goals unlock your apps when you finish them."
        ),
        SlideData(
            icon: "target",
            title: "Stay Anchored",
            description: "Set daily goals to Anchor you down and unlock apps when done."
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
                        .fill(index == currentSlide ? AppColors.accent : AppColors.accent.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(Theme.springAnimationFast, value: currentSlide)
                }
            }
            .padding(.bottom, Theme.spacing)
            
            Button(action: {
                if currentSlide < slides.count - 1 {
                    animate {
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
                    .font(AppTypography.screenTitle).fontWeight(.light)
                    .foregroundColor(AppColors.accent)
            }
            .padding(.bottom, Theme.spacing3)
            
            VStack(spacing: Theme.spacing2) {
                Text(slide.title)
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.onboardingTitleText)
                
                Text(slide.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingBodyText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }
            
            Spacer()
        }
        .padding(Theme.spacing3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sign In Page
struct SignInOnboardingPage: View {
    @ObservedObject var authViewModel: AuthViewModel
    let onSignIn: () -> Void
    @StateObject private var emailAuthViewModel = EmailAuthViewModel()
    @State private var mode: AuthMode = .signIn

    private enum AuthMode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Create Account"
    }
    
    var body: some View {
        VStack(spacing: Theme.spacing4) {
            Spacer()
            
            VStack(spacing: Theme.spacing2) {
                Text("Sign In")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.onboardingTitleText)
                
                Text("Create an account or sign in to continue")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingBodyText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }
            
            Spacer()
            
            VStack(spacing: Theme.spacing2) {
                Picker("Auth Mode", selection: $mode) {
                    ForEach(AuthMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                if mode == .signIn {
                    EmailSignInView(viewModel: emailAuthViewModel) { user in
                        authViewModel.handleAuthenticatedUser(user)
                        onSignIn()
                    }
                } else {
                    EmailSignUpView(viewModel: emailAuthViewModel) { user in
                        authViewModel.handleAuthenticatedUser(user)
                        onSignIn()
                    }
                }
            }
            .padding(.horizontal, Theme.spacing3)
            
            if let errorMessage = emailAuthViewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.horizontal, Theme.spacing3)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Profile Page
struct ProfileOnboardingPage: View {
    @Binding var displayName: String
    @Binding var birthMonth: Int
    @Binding var birthDay: Int
    @Binding var timezone: String
    let onContinue: () -> Void

    private let months = Array(1...12)
    private let days = Array(1...31)

    private var isValid: Bool {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && name.count <= 64
    }

    var body: some View {
        VStack(spacing: Theme.spacing4) {
            Spacer()

            VStack(spacing: Theme.spacing2) {
                Text("Your Profile")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.onboardingTitleText)

                Text("This helps Anchor personalize your experience")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingBodyText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }

            VStack(spacing: Theme.spacing2) {
                TextField("Display name", text: $displayName)
                    .textFieldStyle(AppTextFieldStyle())

                HStack(spacing: Theme.spacing) {
                    Picker("Month", selection: $birthMonth) {
                        ForEach(months, id: \.self) { month in
                            Text("\(month)").tag(month)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Day", selection: $birthDay) {
                        ForEach(days, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, Theme.spacing2)

                TextField("Timezone", text: $timezone)
                    .textFieldStyle(AppTextFieldStyle())
            }
            .padding(.horizontal, Theme.spacing3)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isValid)
            .padding(.horizontal, Theme.spacing3)
            .padding(.bottom, Theme.spacing3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Permissions Explanation Page
struct PermissionsExplanationPage: View {
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing3) {
                VStack(spacing: Theme.spacing2) {
                    Text("Permissions")
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.onboardingTitleText)
                    
                    Text("Anchor needs these permissions to work properly")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.onboardingBodyText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.spacing3)
                .padding(.horizontal, Theme.spacing2)
                
                VStack(spacing: Theme.spacing2) {
                    PermissionExplanationItem(
                        icon: "lock.shield.fill",
                        title: "Screen Time",
                        description: "Anchor needs Screen Time permission to block apps during Anchored Mode"
                    )
                    
                    PermissionExplanationItem(
                        icon: "bell.fill",
                        title: "Notifications",
                        description: "Reminders to Lock & Anchor and track goal completion"
                    )
                }
                .padding(.horizontal, Theme.spacing2)
                
                Button(action: onContinue) {
                    Text("Grant Permissions")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.spacing3)
                .padding(.top, Theme.spacing2)
                .padding(.bottom, Theme.spacing3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .font(AppTypography.body).fontWeight(.medium)
                    .foregroundColor(AppColors.accent)
            }
            
            VStack(alignment: .leading, spacing: Theme.smallSpacing) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingTitleText)
                
                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.onboardingBodyText)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.spacing3) {
            Text("Set Your First Goal")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.onboardingTitleText)
                .padding(.top, Theme.spacing3)
            
            Text("Create a daily habit to stay focused")
                .font(AppTypography.body)
                .foregroundColor(AppColors.onboardingBodyText)
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
                        .foregroundColor(AppColors.onboardingBodyText)
                    
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showGoalCreation) {
            NavigationStack {
                GoalCreationView()
            }
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
