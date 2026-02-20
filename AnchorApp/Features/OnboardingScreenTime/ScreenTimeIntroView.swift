import SwiftUI

struct ScreenTimeIntroView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: Theme.spacing4) {
                Spacer()
                
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.textTertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .opacity(0.6)
                    
                    Image("Anchor_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84, height: 84)
                }
                .padding(.bottom, Theme.spacing3)
                
                VStack(spacing: Theme.spacing2) {
                    Text("Stay Anchored with Anchor")
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Lock selected apps until your goals are complete.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.spacing3)
                }
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.spacing3)
                .padding(.bottom, Theme.spacing3)
            }
        }
    }
}
