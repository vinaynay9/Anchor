import Foundation

// MARK: - Shield Messages
// Optional: Custom messages based on session type or time of day

struct ShieldMessages {
    static func getMessage(for sessionType: String?, timeRemaining: TimeInterval?) -> String {
        if let remaining = timeRemaining, remaining < 300 { // Less than 5 minutes
            return "Almost there! Just \(Int(remaining / 60)) minutes left."
        }
        
        switch sessionType {
        case "work":
            return "Stay focused on your work. This app is blocked."
        case "study":
            return "Keep studying! This app is blocked."
        case "exercise":
            return "Finish your workout first. This app is blocked."
        default:
            return "This app is blocked during your focus session."
        }
    }
}

// MARK: - URL Scheme
public struct ShieldURLScheme {
    public static let anchorApp = "anchor://open"
    public static let unlockRequest = "anchor://unlock-request"
    public static let messagePartner = "anchor://message-partner"
}

