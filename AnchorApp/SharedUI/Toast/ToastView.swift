import SwiftUI

/// Individual toast notification view
struct ToastView: View {
    let toast: ToastModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(AppTypography.body).fontWeight(.semibold)
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
                .fill(AppColors.surfaceElevated.opacity(0.9))
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
        .shadow(color: AppColors.textPrimary.opacity(0.25), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        switch toast.type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch toast.type {
        case .success:
            return AppColors.accent
        case .error:
            return AppColors.error
        case .info:
            return AppColors.textTertiary
        case .warning:
            return AppColors.warning
        }
    }
    
    private var borderGradient: LinearGradient {
        switch toast.type {
        case .success:
            // Lavender → Violet gradient for success
            return LinearGradient(
                colors: [
                    AppColors.textTertiary,
                    AppColors.accent
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
                    AppColors.error.opacity(0.95)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .info:
            // Lavender → Primary gradient for info
            return LinearGradient(
                colors: [
                    AppColors.textTertiary.opacity(0.8),
                    AppColors.primary.opacity(0.8)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .warning:
            // Amber gradient for warning
            return LinearGradient(
                colors: [
                    AppColors.warning.opacity(0.7),
                    AppColors.warning.opacity(0.9)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var borderGlowColor: Color {
        switch toast.type {
        case .success:
            return AppColors.accent
        case .error:
            return AppColors.error
        case .info:
            return AppColors.textTertiary
        case .warning:
            return AppColors.warning
        }
    }
}
