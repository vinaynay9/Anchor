import SwiftUI

struct SessionHomeView: View {
    @StateObject private var viewModel = SessionViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: Theme.padding) {
                if let session = viewModel.activeSession {
                    // Show active session summary
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
                                    .foregroundColor(AppColors.accent)
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
                        
                        NavigationLink(destination: ActiveSessionView(session: session, viewModel: viewModel)) {
                            Text("View Active Session")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, Theme.padding)
                    }
                    .padding(Theme.padding)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.accentLight.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, Theme.padding)
                } else {
                    // Show call-to-action to start session
                    VStack(spacing: Theme.padding * 2) {
                        Text("Start a focus session")
                            .font(AppTypography.title)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Block distractions and stay focused with accountability")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.padding)
                        
                        NavigationLink(destination: SessionSetupView(viewModel: viewModel)) {
                            Text("Start Session")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, Theme.padding)
                    }
                    .padding(Theme.padding * 2)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Sessions")
            .onAppear {
                viewModel.loadActiveSession()
            }
        }
    }
}

