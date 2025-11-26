import SwiftUI

struct ActiveSessionView: View {
    let session: LockSession
    @ObservedObject var viewModel: SessionViewModel
    
    var body: some View {
        VStack(spacing: Theme.padding * 2) {
            Text("Session Active")
                .font(AppTypography.title)
            
            if let timeRemaining = viewModel.timeRemaining {
                Text(formatTime(timeRemaining))
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.primary)
            }
            
            Text("\(session.appsBlocked.count) apps blocked")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            NavigationLink(destination: UnlockRequestDetailView(sessionId: session.id)) {
                Text("Request Unlock")
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal, Theme.padding)
            
            Button(action: {
                viewModel.endSession()
            }) {
                Text("End Session")
            }
            .buttonStyle(DangerButtonStyle())
            .padding(.horizontal, Theme.padding)
        }
        .padding(Theme.padding)
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

