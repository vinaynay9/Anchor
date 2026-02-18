import Foundation

/// Represents app categories that can be blocked during sessions
public enum AppCategory: String, Codable, Hashable, CaseIterable {
    case social = "social"
    case games = "games"
    case entertainment = "entertainment"
    case videoStreaming = "video_streaming"
    
    /// Display name for the category
    public var displayName: String {
        switch self {
        case .social:
            return "Social"
        case .games:
            return "Games"
        case .entertainment:
            return "Entertainment"
        case .videoStreaming:
            return "Video / Streaming"
        }
    }
    
    /// Icon name for the category (for UI)
    public var iconName: String {
        switch self {
        case .social:
            return "person.2.fill"
        case .games:
            return "gamecontroller.fill"
        case .entertainment:
            return "tv.fill"
        case .videoStreaming:
            return "play.rectangle.fill"
        }
    }
}

