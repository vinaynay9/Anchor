import SwiftUI

struct GoalsExplanationView: View {
    @Environment(\.dismiss) var dismiss
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: Theme.spacing4) {
                Spacer()
                
                // Icon
                Image(systemName: "target")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.accent)
                    .padding(.bottom, Theme.spacing)
                
                // Title
                Text("Daily Goals")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.textPrimary)
                
                // Description
                VStack(alignment: .leading, spacing: Theme.spacing2) {
                    Text("Set daily habits to stay Anchored.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Complete all goals to Break Anchor and unlock apps.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Theme.spacing3)
                
                Spacer()
                
                // Continue Button
                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.spacing3)
                .padding(.bottom, Theme.spacing3)
            }
        }
    }
}

