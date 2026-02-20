import SwiftUI

// MARK: - Unified Design System Theme
struct Theme {
    // MARK: - Spacing Scale (8pt grid system)
    static let spacing: CGFloat = 8
    static let spacing2: CGFloat = 16
    static let spacing3: CGFloat = 24
    static let spacing4: CGFloat = 32
    static let spacing5: CGFloat = 40
    static let spacing6: CGFloat = 48
    
    // Legacy aliases for backward compatibility
    static let padding: CGFloat = 16
    static let smallSpacing: CGFloat = 4
    static let largeSpacing: CGFloat = 24
    
    // MARK: - Corner Radius Scale
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24
    static let cornerRadiusXLarge: CGFloat = 32
    
    // MARK: - Animation Constants
    static let animationFast: Double = 0.2
    static let animationMedium: Double = 0.3
    static let animationSlow: Double = 0.5
    
    static let springAnimation = AppMotion.gentleSpring
    static let springAnimationFast = AppMotion.snappy
    static let springAnimationSlow = AppMotion.standard
    
    // MARK: - Shadow Constants
    static let shadowRadius: CGFloat = 12
    static let shadowRadiusLarge: CGFloat = 24
    static let shadowOpacity: Double = 0.15
    static let shadowOpacityLarge: Double = 0.3
    
    // MARK: - Blur Constants (for glassmorphism)
    static let blurRadius: CGFloat = 20
    static let blurRadiusLarge: CGFloat = 40
}
