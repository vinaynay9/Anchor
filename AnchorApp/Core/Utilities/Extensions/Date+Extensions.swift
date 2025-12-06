import Foundation

extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Formats date for activity feed sections (Today, Yesterday, This Week, etc.)
    func activityFeedSectionTitle() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let daysAgo = calendar.dateComponents([.day], from: self, to: now).day ?? 0
            if daysAgo <= 7 {
                return "This Week"
            } else {
                return "Earlier"
            }
        }
    }
}

