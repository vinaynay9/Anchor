import SwiftUI

/// Individual toast notification view
struct ToastView: View {
    let toast: ToastModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(iconColor)
            
            // Message
            Text(toast.message)
                .font(AppTypography.body)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
                .tracking(0.2)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .fill(AppColors.anchorPrimaryDark.opacity(0.9))
                .background(
                    // Frosted glass blur effect
                    RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                )
        )
        .overlay(
            // Vibrant accent border glow
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(borderGradient, lineWidth: 2)
                .shadow(color: borderGlowColor.opacity(0.6), radius: 8, x: 0, y: 0)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        switch toast.type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch toast.type {
        case .success:
            return AppColors.anchorAccent
        case .error:
            return AppColors.error
        }
    }
    
    private var borderGradient: LinearGradient {
        switch toast.type {
        case .success:
            // Lavender → Violet gradient for success
            return LinearGradient(
                colors: [
                    AppColors.anchorLavender,
                    AppColors.anchorAccent
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .error:
            // Reddish-magenta gradient for error
            return LinearGradient(
                colors: [
                    AppColors.error.opacity(0.8),
                    AppColors.error.opacity(0.9),
                    AppColors.error.opacity(0.95) // Magenta tint variant
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var borderGlowColor: Color {
        switch toast.type {
        case .success:
            return AppColors.anchorAccent
        case .error:
            return AppColors.error
        }
    }
}

