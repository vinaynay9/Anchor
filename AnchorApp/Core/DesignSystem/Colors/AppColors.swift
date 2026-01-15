import SwiftUI

struct AppColors {
    // MARK: - Primary Colors (Luxury Blue System)
    static let primaryUnlocked = Color(red: 0.220, green: 0.310, blue: 0.420) // #384F6B - Steel blue
    static let primaryAnchored = Color(red: 0.051, green: 0.078, blue: 0.129) // #0D1421 - Near-black blue
    
    // MARK: - Accent Colors
    static let accentFocus = Color(red: 0.341, green: 0.522, blue: 0.706) // #5785B4 - Muted cerulean
    static let accentMist = Color(red: 0.686, green: 0.772, blue: 0.855) // #AFC5DA - Soft mist blue
    
    // MARK: - Light Mode Colors
    static let backgroundUnlocked = Color(red: 0.961, green: 0.969, blue: 0.980) // #F5F7FA - Clean slate
    static let secondaryBackgroundLight = Color(red: 0.910, green: 0.929, blue: 0.953) // #E8EDF3 - Cool fog
    static let textPrimaryLight = Color(red: 0.055, green: 0.078, blue: 0.110) // #0E141C - Ink
    static let textSecondaryLight = Color(red: 0.298, green: 0.369, blue: 0.463) // #4C5E76 - Slate
    
    // MARK: - Dark Mode Colors
    static let backgroundAnchored = Color(red: 0.035, green: 0.051, blue: 0.075) // #090D13 - Anchored night
    static let secondaryBackgroundDark = Color(red: 0.078, green: 0.106, blue: 0.149) // #141B26 - Deep slate
    static let textPrimaryDark = Color(red: 0.906, green: 0.929, blue: 0.953) // #E7EDF3 - Porcelain
    static let textSecondaryDark = Color(red: 0.639, green: 0.694, blue: 0.753) // #A3B1C0 - Clouded steel
    
    // MARK: - Legacy Anchor Aliases
    static let anchorPrimary = primaryUnlocked
    static let anchorPrimaryDark = primaryAnchored
    static let anchorAccent = accentFocus
    static let anchorLavender = accentMist
    
    // MARK: - Adaptive Colors (Respects system appearance)
    static var background: Color {
        Color(light: backgroundUnlocked, dark: backgroundAnchored)
    }
    
    static var secondaryBackground: Color {
        Color(light: secondaryBackgroundLight, dark: secondaryBackgroundDark)
    }
    
    static var textPrimary: Color {
        Color(light: textPrimaryLight, dark: textPrimaryDark)
    }
    
    static var textSecondary: Color {
        Color(light: textSecondaryLight, dark: textSecondaryDark)
    }
    
    // MARK: - Status Colors
    static let success = Color(red: 0.063, green: 0.725, blue: 0.506) // #10B981 - Muted emerald
    static let warning = Color(red: 0.925, green: 0.694, blue: 0.125) // #ECB120 - Deep amber/gold
    static let error = Color(red: 0.863, green: 0.196, blue: 0.325) // #DC3253 - Rich crimson
    
    // MARK: - Text on Colored Backgrounds
    static let onPrimary = Color.white // For text on primary/accent colored backgrounds
    static let onPrimarySecondary = Color.white.opacity(0.9) // For secondary text on colored backgrounds
    
    // MARK: - Shield Screen Colors
    static let shieldBackground = backgroundAnchored
    static let shieldText = textPrimaryDark
    
    // MARK: - Shadow Colors (Adaptive)
    static let shadowDefault = Color.black.opacity(0.15) // Light mode shadow
    static let shadowDefaultDark = Color.black.opacity(0.3) // Dark mode shadow
    static var shadow: Color {
        Color(light: shadowDefault, dark: shadowDefaultDark)
    }
}

// MARK: - Glassmorphism View Modifiers
struct GlassMaterialModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        AppColors.anchorPrimary.opacity(0.1),
                        AppColors.anchorAccent.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

struct CardMaterialModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        AppColors.anchorLavender.opacity(0.08),
                        AppColors.anchorAccent.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

struct PanelMaterialModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        AppColors.anchorPrimary.opacity(0.12),
                        AppColors.anchorAccent.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

extension View {
    func glassMaterial() -> some View {
        modifier(GlassMaterialModifier())
    }
    
    func cardMaterial() -> some View {
        modifier(CardMaterialModifier())
    }
    
    func panelMaterial() -> some View {
        modifier(PanelMaterialModifier())
    }
}

// MARK: - Color Extension for Light/Dark Mode
extension Color {
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


// MARK: - Layout Constants (Unified)
struct AppLayout {
    // Corner Radius (aligned with Theme)
    static let cardCornerRadius: CGFloat = Theme.cornerRadiusMedium
    static let buttonCornerRadius: CGFloat = Theme.cornerRadiusMedium
    static let chipCornerRadius: CGFloat = Theme.cornerRadius
    static let sheetCornerRadius: CGFloat = Theme.cornerRadiusLarge
    
    // Legacy support
    static let cornerRadius: CGFloat = Theme.cornerRadius
}
