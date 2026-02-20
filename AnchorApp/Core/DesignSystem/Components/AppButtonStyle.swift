import SwiftUI

// MARK: - Primary Button (Luxury Purple Gradient)
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && !reduceMotion
        configuration.label
            .font(AppTypography.button)
            .foregroundColor(AppColors.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing2)
            .padding(.horizontal, Theme.spacing2)
            .background(isPressed ? AppColors.primaryPressed : AppColors.primary)
            .cornerRadius(Theme.cornerRadiusMedium)
            .shadow(color: AppColors.primary.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .opacity(isPressed ? 0.96 : 1.0)
            .animation(AppMotion.animation(AppMotion.snappy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button (Outlined)
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && !reduceMotion
        configuration.label
            .font(AppTypography.button)
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing2)
            .padding(.horizontal, Theme.spacing2)
            .background(AppColors.surfaceElevated)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .opacity(isPressed ? 0.95 : 1.0)
            .animation(AppMotion.animation(AppMotion.snappy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

// MARK: - Tertiary Button (Subtle Text)
struct TertiaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && !reduceMotion
        configuration.label
            .font(AppTypography.body)
            .foregroundColor(AppColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing)
            .padding(.horizontal, Theme.spacing2)
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(AppMotion.animation(AppMotion.snappy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

// MARK: - Danger Button (Destructive)
struct DangerButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && !reduceMotion
        configuration.label
            .font(AppTypography.button)
            .foregroundColor(AppColors.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing2)
            .padding(.horizontal, Theme.spacing2)
            .background(AppColors.error)
            .cornerRadius(Theme.cornerRadiusMedium)
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(AppMotion.animation(AppMotion.snappy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button (Minimal)
struct GhostButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && !reduceMotion
        configuration.label
            .font(AppTypography.body)
            .foregroundColor(AppColors.textSecondary)
            .padding(.vertical, Theme.spacing)
            .padding(.horizontal, Theme.spacing2)
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(AppMotion.animation(AppMotion.snappy, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}
