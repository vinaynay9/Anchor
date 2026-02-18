import Foundation

// MARK: - Anchor App Constants
// Centralized constants for spacing, durations, and other configuration values
// These provide a single source of truth across the entire app

/// Unified spacing constants (8pt grid system)
struct Spacing {
    /// 4pt - Extra small spacing
    static let xs: CGFloat = 4
    /// 8pt - Small spacing
    static let sm: CGFloat = 8
    /// 12pt - Medium-small spacing
    static let md: CGFloat = 12
    /// 16pt - Base spacing
    static let base: CGFloat = 16
    /// 20pt - Medium-large spacing
    static let lg: CGFloat = 20
    /// 24pt - Large spacing
    static let xl: CGFloat = 24
    /// 32pt - Extra large spacing
    static let xxl: CGFloat = 32
    /// 40pt - 2x extra large
    static let xxxl: CGFloat = 40
    /// 48pt - 3x extra large
    static let huge: CGFloat = 48
    
    // Semantic aliases
    static let sectionPadding: CGFloat = base
    static let cardPadding: CGFloat = base
    static let listItemSpacing: CGFloat = md
    static let buttonPadding: CGFloat = base
    static let inputPadding: CGFloat = md
}

/// Unified duration constants for animations and timeouts
struct Durations {
    // MARK: - Animation Durations
    /// 0.15s - Very fast animation (micro-interactions)
    static let animationXFast: Double = 0.15
    /// 0.2s - Fast animation
    static let animationFast: Double = 0.2
    /// 0.3s - Standard animation
    static let animationStandard: Double = 0.3
    /// 0.4s - Medium animation
    static let animationMedium: Double = 0.4
    /// 0.5s - Slow animation
    static let animationSlow: Double = 0.5
    /// 0.8s - Extra slow animation (page transitions)
    static let animationXSlow: Double = 0.8
    
    // MARK: - Debounce Durations
    /// 0.3s - Standard debounce for search
    static let debounceSearch: Double = 0.3
    /// 0.5s - Debounce for expensive operations
    static let debounceExpensive: Double = 0.5
    
    // MARK: - Timeout Durations
    /// 10s - Network request timeout
    static let networkTimeout: Double = 10.0
    /// 30s - Long-running operation timeout
    static let longOperationTimeout: Double = 30.0
    /// 60s - Upload timeout
    static let uploadTimeout: Double = 60.0
    
    // MARK: - Toast/Notification Durations
    /// 2.5s - Standard toast duration
    static let toastStandard: Double = 2.5
    /// 4.0s - Long toast duration (for important messages)
    static let toastLong: Double = 4.0
    /// 1.5s - Short toast duration (for quick feedback)
    static let toastShort: Double = 1.5
    
}

/// Unified layout constants
struct Layout {
    // MARK: - Corner Radius
    /// 4pt - Small corner radius (tags, chips)
    static let cornerRadiusSmall: CGFloat = 4
    /// 8pt - Standard corner radius (buttons, inputs)
    static let cornerRadiusStandard: CGFloat = 8
    /// 12pt - Medium corner radius (cards)
    static let cornerRadiusMedium: CGFloat = 12
    /// 16pt - Large corner radius (modals)
    static let cornerRadiusLarge: CGFloat = 16
    /// 24pt - Extra large corner radius (sheets)
    static let cornerRadiusXLarge: CGFloat = 24
    /// 32pt - Full rounded (circular buttons)
    static let cornerRadiusFull: CGFloat = 32
    
    // MARK: - Icon Sizes
    /// 16pt - Small icon
    static let iconSmall: CGFloat = 16
    /// 20pt - Standard icon
    static let iconStandard: CGFloat = 20
    /// 24pt - Medium icon
    static let iconMedium: CGFloat = 24
    /// 32pt - Large icon
    static let iconLarge: CGFloat = 32
    /// 48pt - Extra large icon
    static let iconXLarge: CGFloat = 48
    
    // MARK: - Button Heights
    /// 44pt - Standard button height (Apple HIG minimum touch target)
    static let buttonHeightStandard: CGFloat = 44
    /// 52pt - Large button height
    static let buttonHeightLarge: CGFloat = 52
    /// 36pt - Small button height
    static let buttonHeightSmall: CGFloat = 36
    
    // MARK: - Avatar Sizes
    /// 32pt - Small avatar
    static let avatarSmall: CGFloat = 32
    /// 40pt - Standard avatar
    static let avatarStandard: CGFloat = 40
    /// 56pt - Medium avatar
    static let avatarMedium: CGFloat = 56
    /// 80pt - Large avatar
    static let avatarLarge: CGFloat = 80
    
    // MARK: - Shadow
    /// 4pt - Small shadow radius
    static let shadowRadiusSmall: CGFloat = 4
    /// 8pt - Standard shadow radius
    static let shadowRadiusStandard: CGFloat = 8
    /// 16pt - Large shadow radius
    static let shadowRadiusLarge: CGFloat = 16
}

/// API and networking constants
struct APIConstants {
    /// Maximum number of retry attempts for network requests
    static let maxRetryAttempts: Int = 3
    /// Base delay between retries (exponential backoff)
    static let retryBaseDelay: Double = 1.0
    /// Maximum concurrent uploads
    static let maxConcurrentUploads: Int = 2
}

/// Storage constants
struct StorageConstants {
    /// Cache expiration time (in hours)
    static let cacheExpirationHours: Int = 24
}
