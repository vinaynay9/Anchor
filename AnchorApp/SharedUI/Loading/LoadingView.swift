import SwiftUI

/// Reusable loading indicator view with optional message
struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: Theme.spacing * 2) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.anchorAccent))
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.padding * 2)
    }
}

/// Full-screen loading overlay
struct LoadingOverlay: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            AppColors.background.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: Theme.spacing * 2) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.anchorAccent))
                    .scaleEffect(1.3)
                
                if let message = message {
                    Text(message)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .padding(Theme.padding * 2)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                    .fill(AppColors.secondaryBackground)
                    .shadow(color: AppColors.anchorAccent.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(Theme.padding * 2)
        }
    }
}

