import SwiftUI

struct OnboardingPermissionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showCompletionAnimation = false
    @State private var screenTimeGranted = false
    @State private var notificationsGranted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: Theme.padding * 2) {
                Spacer()
                
                // Header
                VStack(spacing: Theme.spacing * 2) {
                    Text("Complete Setup")
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.onboardingTitleText)
                        .multilineTextAlignment(.center)
                    
                    Text("Grant permissions to unlock Anchor's full potential")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.onboardingBodyText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.padding * 2)
                }
                .padding(.bottom, Theme.padding * 3)
                
                // Permission checklist
                VStack(spacing: Theme.padding) {
                    PermissionItemView(
                        title: "Screen Time",
                        description: "Required to block apps during Anchored Mode",
                        isGranted: screenTimeGranted,
                        icon: "lock.shield.fill"
                    )
                    
                    PermissionItemView(
                        title: "Notifications",
                        description: "Get reminders when it's time to Anchor your day",
                        isGranted: notificationsGranted,
                        icon: "bell.fill"
                    )
                }
                .padding(.horizontal, Theme.padding * 2)
                
                Spacer()
                
                // Complete Setup button
                Button(action: {
                    viewModel.completeOnboarding()
                    if reduceMotion {
                        showCompletionAnimation = true
                    } else {
                        withAnimation(AppMotion.gentleSpring) {
                            showCompletionAnimation = true
                        }
                    }
                }) {
                    Text("Complete Setup")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.onboardingTitleText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.padding)
                        .background(AppColors.accent)
                        .cornerRadius(AppLayout.buttonCornerRadius)
                }
                .padding(.horizontal, Theme.padding * 2)
                .padding(.bottom, Theme.padding * 2)
                .scaleEffect(showCompletionAnimation ? 0.95 : 1.0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Permission Item View
struct PermissionItemView: View {
    let title: String
    let description: String
    let isGranted: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: Theme.padding) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(AppTypography.body).fontWeight(.medium)
                    .foregroundColor(isGranted ? AppColors.success : AppColors.accent)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingTitleText)
                
                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.onboardingBodyText)
            }
            
            Spacer()
            
            // Status indicator
            ZStack {
                Circle()
                    .fill(isGranted ? AppColors.success : AppColors.textTertiary.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                if isGranted {
                    Image(systemName: "checkmark")
                        .font(AppTypography.caption).fontWeight(.bold)
                        .foregroundColor(AppColors.onPrimary)
                } else {
                    Image(systemName: "exclamationmark")
                        .font(AppTypography.caption).fontWeight(.bold)
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .padding(Theme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .fill(AppColors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                        .stroke(AppColors.textTertiary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
