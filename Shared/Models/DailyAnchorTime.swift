import Foundation

// Legacy compatibility model for AppGroupStorage usage.
public struct DailyAnchorTime: Codable, Hashable {
    public let hour: Int
    public let minute: Int
    
    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}
