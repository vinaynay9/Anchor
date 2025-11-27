import SwiftUI
import Shared

struct ActiveSessionView: View {
    let session: LockSession
    @ObservedObject var viewModel: SessionViewModel
    
    private var sessionDuration: TimeInterval {
        guard let endTime = session.endTime else { return 0 }
        return endTime.timeIntervalSince(session.startTime)
    }
    
    var body: some View {
        VStack(spacing: Theme.padding * 2) {
            Text("Active Session")
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)
            
            // Remaining time with live countdown
            TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                VStack(spacing: Theme.spacing) {
                    Text("Time Remaining")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(formatTime(calculateTimeRemaining(currentTime: context.date)))
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColors.accent)
                }
            }
            
            Divider()
                .background(AppColors.accentLight.opacity(0.1))
                .padding(.vertical, Theme.padding)
            
            // Session details
            VStack(alignment: .leading, spacing: Theme.spacing) {
                HStack {
                    Text("Start Time:")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(session.startTime, style: .time)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if let endTime = session.endTime {
                    HStack {
                        Text("End Time:")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(endTime, style: .time)
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                
                HStack {
                    Text("Duration:")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("\(Int(sessionDuration / 60)) minutes")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if session.accountabilityPartnerId != nil || !viewModel.selectedFriendIds.isEmpty {
                    HStack {
                        Text("Accountability:")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("\(viewModel.selectedFriendIds.count) friend(s)")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding(Theme.padding)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppLayout.chipCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                    .stroke(AppColors.accentLight.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, Theme.padding)
            
            Spacer()
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.horizontal, Theme.padding)
            }
            
            Button(action: {
                viewModel.endSession()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                            .padding(.trailing, Theme.spacing)
                    }
                    Text("End Session")
                }
            }
            .buttonStyle(DangerButtonStyle())
            .padding(.horizontal, Theme.padding)
            .disabled(viewModel.isLoading)
        }
        .padding(Theme.padding)
        .background(AppColors.background)
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func calculateTimeRemaining(currentTime: Date) -> TimeInterval {
        guard let endTime = session.endTime else { return 0 }
        let remaining = endTime.timeIntervalSince(currentTime)
        return max(0, remaining)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

