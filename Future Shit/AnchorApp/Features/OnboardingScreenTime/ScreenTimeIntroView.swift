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
                                colors: [AppColors.anchorPrimary, AppColors.anchorLavender],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .opacity(0.6)
                    
                    Image(systemName: "anchor.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(AppColors.anchorAccent)
                }
                .padding(.bottom, Theme.spacing3)
                
                VStack(spacing: Theme.spacing2) {
                    Text("Stay Accountable with Anchor")
                        .font(AppTypography.display)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Block distractions, stay focused, and let your friends help you unlock apps when you need them")
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

