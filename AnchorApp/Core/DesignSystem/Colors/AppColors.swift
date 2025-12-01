import SwiftUI

struct AppColors {
    // MARK: - Primary Colors (Luxury Purple - Works in both light/dark)
    static let anchorPrimary = Color(red: 0.227, green: 0.047, blue: 0.639) // #3A0CA3 - Deep royal purple
    static let anchorPrimaryDark = Color(red: 0.102, green: 0.039, blue: 0.227) // #1A0A3A - Ultra-dark purple
    
    // MARK: - Accent Colors
    static let anchorAccent = Color(red: 0.545, green: 0.361, blue: 0.965) // #8B5CF6 - Electric violet
    static let anchorLavender = Color(red: 0.769, green: 0.710, blue: 0.992) // #C4B5FD - Soft lavender
    
    // MARK: - Light Mode Colors
    static let backgroundLight = Color(red: 0.98, green: 0.98, blue: 0.99) // #FAFAFC - Soft white
    static let secondaryBackgroundLight = Color(red: 0.95, green: 0.94, blue: 0.97) // #F2F0F7 - Light lavender tint
    static let textPrimaryLight = Color(red: 0.1, green: 0.1, blue: 0.15) // #191926 - Deep charcoal
    static let textSecondaryLight = Color(red: 0.4, green: 0.38, blue: 0.5) // #666680 - Muted purple-gray
    
    // MARK: - Dark Mode Colors
    static let backgroundDark = Color(red: 0.039, green: 0.039, blue: 0.059) // #0A0A0F - Onyx black
    static let secondaryBackgroundDark = Color(red: 0.102, green: 0.102, blue: 0.141) // #1A1A24 - Ultra-dark purple
    static let textPrimaryDark = Color(red: 0.961, green: 0.961, blue: 0.969) // #F5F5F7 - Off-white
    static let textSecondaryDark = Color(red: 0.722, green: 0.702, blue: 0.820) // #B8B3D1 - Soft grey-lavender
    
    // MARK: - Adaptive Colors (Respects system appearance)
    static var background: Color {
        Color(light: backgroundLight, dark: backgroundDark)
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
    static let shieldBackground = Color(red: 0.020, green: 0.020, blue: 0.035) // #050509 - Ultra-dark
    static let shieldText = Color(red: 0.961, green: 0.961, blue: 0.969) // #F5F5F7 - High-contrast white
    
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

