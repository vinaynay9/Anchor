import SwiftUI

/// Reusable empty state view with icon, title, and optional message
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String?
    let actionTitle: String?
    let action: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(
        icon: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Theme.spacing * 3) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary.opacity(0.2),
                                AppColors.accent.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(AppTypography.screenTitle).fontWeight(.light)
                    .foregroundColor(AppColors.accent.opacity(0.7))
            }
            .padding(.bottom, Theme.spacing)
            
            // Title
            Text(title)
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Message
            if let message = message {
                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.padding * 2)
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    if reduceMotion {
                        action()
                    } else {
                        withAnimation(AppMotion.gentleSpring) {
                            action()
                        }
                    }
                }) {
                    Text(actionTitle)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, Theme.padding * 2)
                .padding(.top, Theme.spacing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.padding * 3)
    }
}
