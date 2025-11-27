import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showPermissionStep = false
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            if showPermissionStep {
                OnboardingPermissionStepView(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                VStack(spacing: 0) {
                    // Page content
                    TabView(selection: $viewModel.currentPage) {
                        WelcomePage()
                            .tag(0)
                        
                        AppBlockingPage()
                            .tag(1)
                        
                        FriendsAccountabilityPage()
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
                    
                    // Bottom section with dots and button
                    VStack(spacing: Theme.padding * 1.5) {
                        // Pager dots
                        HStack(spacing: 8) {
                            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                                Circle()
                                    .fill(index == viewModel.currentPage ? AppColors.accent : AppColors.accent.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
                            }
                        }
                        .padding(.top, Theme.padding)
                        
                        // Continue button
                        Button(action: {
                            if viewModel.isLastPage {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showPermissionStep = true
                                }
                            } else {
                                viewModel.nextPage()
                            }
                        }) {
                            Text(viewModel.isLastPage ? "Get Started" : "Continue")
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.padding)
                                .background(AppColors.accent)
                                .cornerRadius(AppLayout.buttonCornerRadius)
                        }
                        .padding(.horizontal, Theme.padding * 2)
                        .padding(.bottom, Theme.padding * 2)
                    }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
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
                            colors: [AppColors.primary, AppColors.accentLight],
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
                    .foregroundColor(AppColors.accent)
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
                    .foregroundColor(AppColors.accent)
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
                    .foregroundColor(AppColors.accent)
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

