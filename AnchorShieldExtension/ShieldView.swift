import SwiftUI
import ManagedSettingsUI

// MARK: - Shield View
// This view is shown when a user tries to open a blocked app

struct ShieldView: View {
    @StateObject private var viewModel = ShieldViewModel()
    let context: ShieldConfigurationContext
    
    var body: some View {
        ZStack {
            ShieldColors.shieldBackground
                .ignoresSafeArea()
            
            VStack(spacing: ShieldTheme.padding * 2) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ShieldColors.shieldText)
                
                Text(viewModel.message)
                    .font(ShieldTypography.title2)
                    .foregroundColor(ShieldColors.shieldText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ShieldTheme.padding)
                
                if let timeRemaining = viewModel.timeRemaining {
                    Text(formatTime(timeRemaining))
                        .font(ShieldTypography.largeTitle)
                        .foregroundColor(ShieldColors.shieldText.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: {
                    // Dismiss shield and return to home screen
                    // The system will handle this automatically
                }) {
                    Text("Go Home")
                        .font(ShieldTypography.bodyBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ShieldColors.primary)
                        .cornerRadius(ShieldTheme.cornerRadius)
                }
                .padding(.horizontal, ShieldTheme.padding)
                .padding(.bottom, ShieldTheme.padding * 2)
            }
        }
        .onAppear {
            viewModel.loadSessionState()
        }
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

