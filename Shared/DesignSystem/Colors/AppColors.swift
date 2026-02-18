import SwiftUI

public enum AppColors {
    // MARK: - Base Colors
    public static let background = Color(hex: "#0F0525")
    public static let background2 = Color(hex: "#1E0954")

    public static let surface = Color(hex: "#150733")
    public static let surfaceElevated = Color(hex: "#1E0954")
    public static let border = Color(hex: "#2A0C74")

    public static let primary = Color(hex: "#4C1DDE")
    public static let primaryPressed = Color(hex: "#3D22D3")
    public static let accent = Color(hex: "#5B3EFD")

    public static let textPrimary = Color(hex: "#FFFFFF")
    public static let textSecondary = Color(hex: "#C9BBF5")
    public static let textTertiary = Color(hex: "#A58EEE")

    // MARK: - Gradients
    public static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [background, background2], startPoint: .top, endPoint: .bottom)
    }

    public static var brandGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: "#410ECA"), accent], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - Semantic Tokens
    public static let screenBackground = background
    public static let cardBackground = surface
    public static let separator = border
    public static let ctaBackground = primary
    public static let ctaText = textPrimary
    public static let secondaryButtonBackground = surfaceElevated
    public static let secondaryButtonText = textSecondary
}

public extension Color {
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        let scanner = Scanner(string: cleaned)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
