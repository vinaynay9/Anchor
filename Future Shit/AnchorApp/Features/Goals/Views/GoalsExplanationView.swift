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
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.anchorAccent)
                    .padding(.bottom, Theme.spacing)
                
                // Title
                Text("Daily Goals")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                
                // Description
                VStack(alignment: .leading, spacing: Theme.spacing2) {
                    Text("Set daily habits to stay focused and accountable.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Complete all goals to unlock your apps, or request an unlock with proof.")
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

