import SwiftUI

extension AppColors {
    static var accent: Color { primary }
    static var textTertiary: Color { textSecondary.opacity(0.75) }
    static var border: Color { textSecondary.opacity(0.25) }
}

struct AnchorTheme {
    static let background = AppColors.background
    static let cardBackground = AppColors.surface
    static let accent = AppColors.accent
    static let primary = AppColors.primary
    static let textPrimary = AppColors.textPrimary
    static let textSecondary = AppColors.textSecondary
    static let textTertiary = AppColors.textTertiary

    static let cornerRadius: CGFloat = 16
    static let shadow = Color.black.opacity(0.25)

    struct Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    struct Typography {
        static let title = Font.system(size: 30, weight: .semibold, design: .rounded)
        static let subtitle = Font.system(size: 17, weight: .regular, design: .rounded)
        static let body = Font.system(size: 15, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AnchorTheme.Typography.body)
                .foregroundColor(AnchorTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AnchorTheme.Spacing.md)
                .background(disabled ? AnchorTheme.primary.opacity(0.4) : AnchorTheme.primary)
                .cornerRadius(AnchorTheme.cornerRadius)
        }
        .disabled(disabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AnchorTheme.Typography.body)
                .foregroundColor(AnchorTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AnchorTheme.Spacing.md)
                .background(AnchorTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AnchorTheme.cornerRadius)
                        .stroke(AppColors.border.opacity(0.6), lineWidth: 1)
                )
                .cornerRadius(AnchorTheme.cornerRadius)
        }
        .disabled(disabled)
    }
}

struct OnboardingCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AnchorTheme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(AnchorTheme.cardBackground)
            .cornerRadius(AnchorTheme.cornerRadius)
            .shadow(color: AnchorTheme.shadow, radius: 12, x: 0, y: 6)
    }
}
