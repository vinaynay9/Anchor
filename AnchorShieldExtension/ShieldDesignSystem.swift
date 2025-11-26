import SwiftUI

// MARK: - Shield Extension Design System
// Minimal design system for the shield extension
// Note: In a real project, these would be shared via a framework or duplicated

struct ShieldTheme {
    static let cornerRadius: CGFloat = 14
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 8
}

struct ShieldColors {
    static let shieldBackground = Color(red: 0.020, green: 0.020, blue: 0.035) // #050509 - ultra-dark purple/black matte
    static let shieldText = Color(red: 0.961, green: 0.961, blue: 0.969) // #F5F5F7 - high-contrast soft white
    static let primary = Color(red: 0.545, green: 0.361, blue: 0.965) // #8B5CF6 - soft electric violet (accent)
    static let accentLight = Color(red: 0.769, green: 0.710, blue: 0.992) // #C4B5FD - lavender highlight
}

struct ShieldTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let bodyBold = Font.system(size: 17, weight: .semibold)
}

