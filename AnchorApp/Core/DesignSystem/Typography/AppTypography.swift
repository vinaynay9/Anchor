import SwiftUI

// MARK: - Unified Typography System
struct AppTypography {
    // MARK: - Display (Large Headings)
    static let display = Font.system(size: 48, weight: .bold, design: .rounded)
    static let display2 = Font.system(size: 40, weight: .bold, design: .rounded)
    
    // MARK: - Headings
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body Text
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)
    static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)
    
    // MARK: - Subheadings
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let subheadlineBold = Font.system(size: 15, weight: .semibold, design: .default)
    
    // MARK: - Caption
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 13, weight: .semibold, design: .default)
    static let caption2 = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2Bold = Font.system(size: 12, weight: .semibold, design: .default)
    
    // MARK: - Labels
    static let label = Font.system(size: 11, weight: .medium, design: .default)
    static let labelBold = Font.system(size: 11, weight: .bold, design: .default)
}

