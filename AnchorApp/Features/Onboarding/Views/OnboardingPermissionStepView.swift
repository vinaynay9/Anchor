import SwiftUI

struct OnboardingPermissionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showCompletionAnimation = false
    
    init(viewModel: OnboardingViewModel = OnboardingViewModel()) {
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
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Grant permissions to unlock Anchor's full potential")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.padding * 2)
                }
                .padding(.bottom, Theme.padding * 3)
                
                // Permission checklist
                VStack(spacing: Theme.padding) {
                    PermissionItemView(
                        title: "Screen Time",
                        description: "Required to block apps during focus sessions",
                        isGranted: viewModel.screenTimePermissionGranted,
                        icon: "lock.shield.fill"
                    )
                    
                    PermissionItemView(
                        title: "Notifications",
                        description: "Get reminders and unlock requests from friends",
                        isGranted: viewModel.notificationsPermissionGranted,
                        icon: "bell.fill"
                    )
                }
                .padding(.horizontal, Theme.padding * 2)
                
                Spacer()
                
                // Complete Setup button
                Button(action: {
                    viewModel.completeOnboarding()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showCompletionAnimation = true
                    }
                }) {
                    Text("Complete Setup")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.padding)
                        .background(AppColors.anchorAccent)
                        .cornerRadius(AppLayout.buttonCornerRadius)
                }
                .padding(.horizontal, Theme.padding * 2)
                .padding(.bottom, Theme.padding * 2)
                .scaleEffect(showCompletionAnimation ? 0.95 : 1.0)
            }
        }
        .onAppear {
            // Check permissions when view appears (mock)
            viewModel.checkScreenTimePermission()
            viewModel.checkNotificationsPermission()
        }
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
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isGranted ? AppColors.success : AppColors.anchorAccent)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Status indicator
            ZStack {
                Circle()
                    .fill(isGranted ? AppColors.success : AppColors.anchorLavender.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                if isGranted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.anchorAccent)
                }
            }
        }
        .padding(Theme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .fill(AppColors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                        .stroke(AppColors.anchorLavender.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

