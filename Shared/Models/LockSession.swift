import Foundation

struct LockSession: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let status: SessionStatus
    let startTime: Date
    let endTime: Date?
    let appsBlocked: [String] // Bundle identifiers
    let accountabilityPartnerId: UUID?
    let createdAt: Date
    let selectedCategories: [AppCategory]? // Selected app categories to block
    let schedule: LockSessionSchedule? // Schedule configuration for recurring sessions
    var events: [SessionEvent] = [] // Timeline of events for this session
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case startTime = "start_time"
        case endTime = "end_time"
        case appsBlocked = "apps_blocked"
        case accountabilityPartnerId = "accountability_partner_id"
        case createdAt = "created_at"
        case selectedCategories = "selected_categories"
        case schedule
        case events
    }
    
    init(
        id: UUID,
        userId: UUID,
        status: SessionStatus,
        startTime: Date,
        endTime: Date?,
        appsBlocked: [String],
        accountabilityPartnerId: UUID?,
        createdAt: Date,
        selectedCategories: [AppCategory]? = nil,
        schedule: LockSessionSchedule? = nil,
        events: [SessionEvent] = []
    ) {
        self.id = id
        self.userId = userId
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.appsBlocked = appsBlocked
        self.accountabilityPartnerId = accountabilityPartnerId
        self.createdAt = createdAt
        self.selectedCategories = selectedCategories
        self.schedule = schedule
        self.events = events
    }
    
    mutating func addEvent(_ event: SessionEvent) {
        events.append(event)
    }
}

/// Represents a schedule configuration for recurring sessions
public struct LockSessionSchedule: Codable, Hashable {
    /// Days of the week when the schedule applies (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
    public let weekdays: Set<Int>
    /// Start time of the schedule (hour and minute)
    public let startTime: TimeOfDay
    /// End time of the schedule (hour and minute)
    public let endTime: TimeOfDay
    /// Duration of each session in minutes
    public let durationMinutes: Int
    
    public init(weekdays: Set<Int>, startTime: TimeOfDay, endTime: TimeOfDay, durationMinutes: Int) {
        self.weekdays = weekdays
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
    }
}

/// Represents a time of day (hour and minute)
public struct TimeOfDay: Codable, Hashable {
    public let hour: Int // 0-23
    public let minute: Int // 0-59
    
    public init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }
    
    /// Creates a TimeOfDay from a Date (using current calendar)
    public static func from(_ date: Date) -> TimeOfDay {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return TimeOfDay(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }
    
    /// Converts to DateComponents for use with Calendar
    public var dateComponents: DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }
}

enum SessionStatus: String, Codable, Hashable {
    case active
    case completed
    case cancelled
}

// MARK: - API DTOs
struct LockSessionDTO: Codable {
    let id: String
    let userId: String
    let status: String
    let startTime: String
    let endTime: String?
    let appsBlocked: [String]
    let accountabilityPartnerId: String?
    let createdAt: String
    let selectedCategories: [String]?
    let schedule: LockSessionScheduleDTO?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case startTime = "start_time"
        case endTime = "end_time"
        case appsBlocked = "apps_blocked"
        case accountabilityPartnerId = "accountability_partner_id"
        case createdAt = "created_at"
        case selectedCategories = "selected_categories"
        case schedule
    }
    
    func toLockSession() -> LockSession? {
        let formatter = ISO8601DateFormatter()
        guard let uuid = UUID(uuidString: id),
              let userIdUUID = UUID(uuidString: userId),
              let statusEnum = SessionStatus(rawValue: status),
              let startTimeDate = formatter.date(from: startTime),
              let createdAtDate = formatter.date(from: createdAt) else {
            return nil
        }
        
        let endTimeDate = endTime.flatMap { formatter.date(from: $0) }
        let accountabilityPartnerUUID = accountabilityPartnerId.flatMap { UUID(uuidString: $0) }
        
        // Parse selected categories if present
        let categories = selectedCategories?.compactMap { AppCategory(rawValue: $0) }
        
        // Parse schedule if present
        let scheduleValue = schedule?.toLockSessionSchedule()
        
        return LockSession(
            id: uuid,
            userId: userIdUUID,
            status: statusEnum,
            startTime: startTimeDate,
            endTime: endTimeDate,
            appsBlocked: appsBlocked,
            accountabilityPartnerId: accountabilityPartnerUUID,
            createdAt: createdAtDate,
            selectedCategories: categories,
            schedule: scheduleValue,
            events: [] // Events will be loaded separately or added during session lifecycle
        )
    }
}

struct LockSessionScheduleDTO: Codable {
    let weekdays: [Int]
    let startTime: TimeOfDayDTO
    let endTime: TimeOfDayDTO
    let durationMinutes: Int
    
    func toLockSessionSchedule() -> LockSessionSchedule {
        return LockSessionSchedule(
            weekdays: Set(weekdays),
            startTime: startTime.toTimeOfDay(),
            endTime: endTime.toTimeOfDay(),
            durationMinutes: durationMinutes
        )
    }
}

struct TimeOfDayDTO: Codable {
    let hour: Int
    let minute: Int
    
    func toTimeOfDay() -> TimeOfDay {
        return TimeOfDay(hour: hour, minute: minute)
    }
}

