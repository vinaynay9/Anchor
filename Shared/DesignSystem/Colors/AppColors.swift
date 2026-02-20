import SwiftUI

public enum AppColors {
    // MARK: - Brand Purple System (Logo-Derived)
    public static let brandBackgroundDark = Color(red: 0.047, green: 0.016, blue: 0.141) // #0C0424
    public static let brandSurface = Color(red: 0.118, green: 0.035, blue: 0.329) // #1E0954
    public static let brandAccent = Color(red: 0.357, green: 0.243, blue: 0.992) // #5B3EFD
    public static let brandAccentSoft = Color(red: 0.298, green: 0.110, blue: 0.863) // #4C1CDC
    public static let textPrimaryDarkMode = Color(red: 0.980, green: 0.976, blue: 1.000) // #FAF9FF
    public static let textSecondaryDarkMode = Color(red: 0.788, green: 0.733, blue: 0.961) // #C9BBF5
    public static let textTertiaryDarkMode = Color(red: 0.647, green: 0.557, blue: 0.933) // #A58EEE

    // MARK: - Semantic Tokens (Dark-First)
    public static let background = brandBackgroundDark
    public static let surface = brandSurface
    public static let surfaceElevated = brandSurface.opacity(0.92)
    public static let border = brandAccentSoft.opacity(0.3)
    public static let textPrimary = textPrimaryDarkMode
    public static let textSecondary = textSecondaryDarkMode
    public static let textTertiary = textTertiaryDarkMode

    // MARK: - Brand Aliases (Compatibility)
    public static let primary = brandAccent
    public static let primaryPressed = Color(red: 0.302, green: 0.133, blue: 0.827) // #4D22D3
    public static let accent = brandAccent
    public static let secondaryBackground = surface

    // MARK: - Status Colors
    public static let success = Color(red: 0.063, green: 0.725, blue: 0.506)
    public static let warning = Color(red: 0.925, green: 0.694, blue: 0.125)
    public static let danger = Color(red: 0.863, green: 0.196, blue: 0.325)
    public static let error = danger

    // MARK: - Compat Text/Shield
    public static let onPrimary = textPrimary
    public static let onPrimarySecondary = textPrimary.opacity(0.9)
    public static let shieldBackground = background
    public static let shieldText = textPrimary
}
