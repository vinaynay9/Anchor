import SwiftUI

public enum AppColors {
    // MARK: - Primary Colors (Luxury Blue System)
    public static let primaryUnlocked = Color(red: 0.220, green: 0.310, blue: 0.420)
    public static let primaryAnchored = Color(red: 0.051, green: 0.078, blue: 0.129)
    
    // MARK: - Accent Colors
    public static let accentFocus = Color(red: 0.341, green: 0.522, blue: 0.706)
    public static let accentMist = Color(red: 0.686, green: 0.772, blue: 0.855)
    
    // MARK: - Light Mode Colors
    public static let backgroundUnlocked = Color(red: 0.961, green: 0.969, blue: 0.980)
    public static let secondaryBackgroundLight = Color(red: 0.910, green: 0.929, blue: 0.953)
    public static let textPrimaryLight = Color(red: 0.055, green: 0.078, blue: 0.110)
    public static let textSecondaryLight = Color(red: 0.298, green: 0.369, blue: 0.463)
    
    // MARK: - Dark Mode Colors
    public static let backgroundAnchored = Color(red: 0.035, green: 0.051, blue: 0.075)
    public static let secondaryBackgroundDark = Color(red: 0.078, green: 0.106, blue: 0.149)
    public static let textPrimaryDark = Color(red: 0.906, green: 0.929, blue: 0.953)
    public static let textSecondaryDark = Color(red: 0.639, green: 0.694, blue: 0.753)
    
    // MARK: - Legacy Anchor Aliases
    public static let anchorPrimary = primaryUnlocked
    public static let anchorPrimaryDark = primaryAnchored
    public static let anchorAccent = accentFocus
    public static let anchorLavender = accentMist
    
    // MARK: - Adaptive Colors
    public static var background: Color {
        Color(light: backgroundUnlocked, dark: backgroundAnchored)
    }
    
    public static var surface: Color {
        Color(light: secondaryBackgroundLight, dark: secondaryBackgroundDark)
    }

    // Legacy alias for design system drift
    public static var secondaryBackground: Color {
        surface
    }
    
    public static var textPrimary: Color {
        Color(light: textPrimaryLight, dark: textPrimaryDark)
    }
    
    public static var textSecondary: Color {
        Color(light: textSecondaryLight, dark: textSecondaryDark)
    }
    
    // MARK: - Status Colors
    public static let success = Color(red: 0.063, green: 0.725, blue: 0.506)
    public static let warning = Color(red: 0.925, green: 0.694, blue: 0.125)
    public static let danger = Color(red: 0.863, green: 0.196, blue: 0.325)
    public static let error = danger
    
    // MARK: - Compatibility Aliases
    public static let primary = anchorAccent
    public static let onPrimary = Color.white
    public static let onPrimarySecondary = Color.white.opacity(0.9)
    public static let shieldBackground = backgroundAnchored
    public static let shieldText = textPrimaryDark
}

private extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                return UIColor(light)
            case .dark:
                return UIColor(dark)
            @unknown default:
                return UIColor(light)
            }
        })
    }
}
