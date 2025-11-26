import SwiftUI

// MARK: - Shield Extension Design System
// Minimal design system for the shield extension
// Note: In a real project, these would be shared via a framework or duplicated

struct ShieldTheme {
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 8
}

struct ShieldColors {
    static let shieldBackground = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let shieldText = Color.white
    static let primary = Color(red: 0.2, green: 0.4, blue: 0.8)
}

struct ShieldTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let bodyBold = Font.system(size: 17, weight: .semibold)
}

