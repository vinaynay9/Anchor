import SwiftUI
import Shared

struct SessionHomeView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @StateObject private var viewModel = SessionViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Error Banner
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.horizontal, Theme.padding)
                    .padding(.top, Theme.spacing)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content
                if viewModel.isLoading && viewModel.activeSession == nil {
                    LoadingView(message: "Loading session...")
                } else if let session = viewModel.activeSession {
                    // Show active session summary
                    activeSessionCard(session: session)
                        .padding(.horizontal, Theme.padding)
                        .padding(.top, Theme.padding)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                } else {
                    // Show call-to-action to start session
                    emptyStateCard
                        .padding(.horizontal, Theme.padding)
                        .padding(.top, Theme.padding * 2)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Spacer()
            }
        }
        .navigationTitle("Sessions")
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.activeSession != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoading)
        .onAppear {
            viewModel.loadActiveSession()
        }
    }
    
    private func activeSessionCard(session: LockSession) -> some View {
        VStack(spacing: Theme.padding * 2) {
            Text("Active Session")
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)
            
            if let endTime = session.endTime {
                VStack(spacing: Theme.spacing) {
                    Text("Ends at")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(endTime, style: .time)
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.anchorAccent)
                }
                .padding(.vertical, Theme.padding)
            }
            
            if let endTime = session.endTime {
                let duration = endTime.timeIntervalSince(session.startTime)
                let minutes = Int(duration / 60)
                Text("Duration: \(minutes) minutes")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            if session.accountabilityPartnerId != nil {
                let friendCount = viewModel.selectedFriendIds.isEmpty ? 1 : viewModel.selectedFriendIds.count
                Text("Accountability: \(friendCount) friend(s)")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    coordinator.navigateToActiveSession(session: session)
                }
            }) {
                Text("View Active Session")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.padding)
        }
        .padding(Theme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.secondaryBackground,
                            AppColors.secondaryBackground.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.anchorLavender.opacity(0.3),
                            AppColors.anchorAccent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private var emptyStateCard: some View {
        VStack(spacing: Theme.padding * 2) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.anchorPrimary.opacity(0.3),
                                AppColors.anchorAccent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "timer")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(AppColors.anchorAccent)
            }
            
            Text("Start a focus session")
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Block distractions and stay focused with accountability")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.padding)
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    coordinator.navigateToSessionSetup()
                }
            }) {
                Text("Start Session")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.padding)
        }
        .padding(Theme.padding * 2)
        .frame(maxWidth: .infinity)
    }
}

