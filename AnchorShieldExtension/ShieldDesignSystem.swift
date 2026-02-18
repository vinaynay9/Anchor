import SwiftUI
import Shared

struct ShieldTheme {
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 20
    static let spacing: CGFloat = 12
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24

    static let animationDuration: Double = 0.25
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    static let easeInOut = Animation.easeInOut(duration: 0.25)
}

struct ShieldColors {
    static let shieldBackground = AppColors.background
    static let textPrimary = AppColors.textPrimary
    static let textSecondary = AppColors.textSecondary
    static let primary = AppColors.primary
    static let accent = AppColors.accent
    static let border = AppColors.border
}

struct ShieldTypography {
    static let largeTitle = Font.system(size: 30, weight: .semibold, design: .default)
    static let title = Font.system(size: 22, weight: .semibold, design: .default)
    static let title2 = Font.system(size: 18, weight: .medium, design: .default)
    static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let caption = Font.system(size: 13, weight: .medium, design: .default)
    static let smallCaption = Font.system(size: 12, weight: .regular, design: .default)
}
