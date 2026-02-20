import SwiftUI

enum TabItem: String, CaseIterable, Identifiable {
    case home
    case settings
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .home:
            return "house.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .home:
            return "Home"
        case .settings:
            return "Settings"
        }
    }
}
