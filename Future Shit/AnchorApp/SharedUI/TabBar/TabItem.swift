import SwiftUI

enum TabItem: String, CaseIterable, Identifiable {
    case home
    case sessions
    case apps
    case friends
    case settings
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .home:
            return "house.fill"
        case .sessions:
            return "lock.fill"
        case .apps:
            return "square.grid.2x2.fill"
        case .friends:
            return "person.2.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .home:
            return "Home"
        case .sessions:
            return "Sessions"
        case .apps:
            return "Apps"
        case .friends:
            return "Friends"
        case .settings:
            return "Settings"
        }
    }
}

