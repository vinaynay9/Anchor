import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.985
    var pressedOpacity: Double = 0.94
    var animation: Animation = AppMotion.snappy

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && !reduceMotion
        return configuration.label
            .scaleEffect(isPressed ? scale : 1.0)
            .opacity(isPressed ? pressedOpacity : 1.0)
            .animation(AppMotion.animation(animation, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

struct PrimaryPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && !reduceMotion
        return configuration.label
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

struct SecondaryPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && !reduceMotion
        return configuration.label
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
