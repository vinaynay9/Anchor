import SwiftUI

// MARK: - Primary Button (Luxury Purple Gradient)
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyBold)
            .foregroundColor(AppColors.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing2)
            .padding(.horizontal, Theme.spacing2)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.anchorAccent,
                        AppColors.anchorPrimary
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.cornerRadiusMedium)
            .shadow(
                color: AppColors.anchorAccent.opacity(configuration.isPressed ? 0.2 : 0.3),
                radius: configuration.isPressed ? Theme.shadowRadius * 0.7 : Theme.shadowRadius,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.springAnimationFast, value: configuration.isPressed)
    }
}

// MARK: - Secondary Button (Outlined)
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyBold)
            .foregroundColor(AppColors.anchorAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing2)
            .padding(.horizontal, Theme.spacing2)
            .background(Color.clear)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.anchorAccent.opacity(0.6),
                                AppColors.anchorLavender.opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(Theme.springAnimationFast, value: configuration.isPressed)
    }
}

// MARK: - Tertiary Button (Subtle Text)
struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyMedium)
            .foregroundColor(AppColors.anchorAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing)
            .padding(.horizontal, Theme.spacing2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(Theme.springAnimationFast, value: configuration.isPressed)
    }
}

// MARK: - Danger Button (Destructive)
struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyBold)
            .foregroundColor(AppColors.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing2)
            .padding(.horizontal, Theme.spacing2)
            .background(AppColors.error)
            .cornerRadius(Theme.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(Theme.springAnimationFast, value: configuration.isPressed)
    }
}

// MARK: - Ghost Button (Minimal)
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.body)
            .foregroundColor(AppColors.textSecondary)
            .padding(.vertical, Theme.spacing)
            .padding(.horizontal, Theme.spacing2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(Theme.springAnimationFast, value: configuration.isPressed)
    }
}

