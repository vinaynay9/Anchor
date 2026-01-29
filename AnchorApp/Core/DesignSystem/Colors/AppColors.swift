import SwiftUI
import Shared

typealias AppColors = Shared.AppColors

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
