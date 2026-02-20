import SwiftUI
import Shared

// MARK: - Shield Extension Design System
// Uses AppColors anchor variants for brand consistency

struct ShieldTheme {
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 20
    static let spacing: CGFloat = 12
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24
    
    // Animation constants (lightweight for extension)
    static let animationDuration: Double = 0.25
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    static let easeInOut = Animation.easeInOut(duration: 0.25)
}

struct ShieldColors {
    // Use AppColors anchor variants for brand consistency
    static let shieldBackground = AppColors.shieldBackground
    static let shieldText = AppColors.shieldText
    static let primary = AppColors.accent
    static let primaryDark = AppColors.primary
    static let accentLight = AppColors.textTertiary
    static let textSecondary = AppColors.textSecondary
    static let textTertiary = AppColors.textSecondary.opacity(0.7)
    
    // Button colors
    static let primaryButtonBackground = AppColors.accent
    static let secondaryButtonBackground = AppColors.primary.opacity(0.3)
    static let secondaryButtonBorder = AppColors.textTertiary.opacity(0.4)
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
