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
    let lockPlanId: UUID?
    let lockPlanType: LockPlanType
    let lockMode: LockMode
    let unlockPolicy: UnlockPolicy
    let goalRequirement: GoalRequirement
    let quorumState: QuorumState?
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
        case lockPlanId = "lock_plan_id"
        case lockPlanType = "lock_plan_type"
        case lockMode = "lock_mode"
        case unlockPolicy = "unlock_policy"
        case goalRequirement = "goal_requirement"
        case quorumState = "quorum_state"
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
        lockPlanId: UUID? = nil,
        lockPlanType: LockPlanType = .custom,
        lockMode: LockMode = .individual,
        unlockPolicy: UnlockPolicy = .selfUnlock,
        goalRequirement: GoalRequirement = .none,
        quorumState: QuorumState? = nil,
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
        self.lockPlanId = lockPlanId
        self.lockPlanType = lockPlanType
        self.lockMode = lockMode
        self.unlockPolicy = unlockPolicy
        self.goalRequirement = goalRequirement
        self.quorumState = quorumState
        self.events = events
    }
    
    mutating func addEvent(_ event: SessionEvent) {
        events.append(event)
    }
}

// MARK: - Custom Decoding for Backward Compatibility
extension LockSession {
    init(from decoder: Decoder) throws {
        // Migration default: legacy sessions map to individual + self unlock + custom plan.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        status = try container.decode(SessionStatus.self, forKey: .status)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        appsBlocked = try container.decode([String].self, forKey: .appsBlocked)
        accountabilityPartnerId = try container.decodeIfPresent(UUID.self, forKey: .accountabilityPartnerId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        selectedCategories = try container.decodeIfPresent([AppCategory].self, forKey: .selectedCategories)
        schedule = try container.decodeIfPresent(LockSessionSchedule.self, forKey: .schedule)
        lockPlanId = try container.decodeIfPresent(UUID.self, forKey: .lockPlanId)
        lockPlanType = (try container.decodeIfPresent(LockPlanType.self, forKey: .lockPlanType)) ?? .custom
        lockMode = (try container.decodeIfPresent(LockMode.self, forKey: .lockMode)) ?? .individual
        unlockPolicy = (try container.decodeIfPresent(UnlockPolicy.self, forKey: .unlockPolicy)) ?? .selfUnlock
        goalRequirement = (try container.decodeIfPresent(GoalRequirement.self, forKey: .goalRequirement)) ?? .none
        quorumState = try container.decodeIfPresent(QuorumState.self, forKey: .quorumState)
        events = (try container.decodeIfPresent([SessionEvent].self, forKey: .events)) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(status, forKey: .status)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(appsBlocked, forKey: .appsBlocked)
        try container.encodeIfPresent(accountabilityPartnerId, forKey: .accountabilityPartnerId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(selectedCategories, forKey: .selectedCategories)
        try container.encodeIfPresent(schedule, forKey: .schedule)
        try container.encodeIfPresent(lockPlanId, forKey: .lockPlanId)
        try container.encode(lockPlanType, forKey: .lockPlanType)
        try container.encode(lockMode, forKey: .lockMode)
        try container.encode(unlockPolicy, forKey: .unlockPolicy)
        try container.encode(goalRequirement, forKey: .goalRequirement)
        try container.encodeIfPresent(quorumState, forKey: .quorumState)
        try container.encode(events, forKey: .events)
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
    let lockPlanId: String?
    let lockPlanType: String?
    let lockMode: String?
    let unlockPolicy: String?
    let goalRequirement: String?
    let quorumState: QuorumState?
    
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
        case lockPlanId = "lock_plan_id"
        case lockPlanType = "lock_plan_type"
        case lockMode = "lock_mode"
        case unlockPolicy = "unlock_policy"
        case goalRequirement = "goal_requirement"
        case quorumState = "quorum_state"
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
        let lockPlanUUID = lockPlanId.flatMap { UUID(uuidString: $0) }
        
        // Parse selected categories if present
        let categories = selectedCategories?.compactMap { AppCategory(rawValue: $0) }
        
        // Parse schedule if present
        let scheduleValue = schedule?.toLockSessionSchedule()
        
        let lockPlanTypeValue = lockPlanType.flatMap { LockPlanType(rawValue: $0) } ?? .custom
        let lockModeValue = lockMode.flatMap { LockMode(rawValue: $0) } ?? .individual
        let unlockPolicyValue = unlockPolicy.flatMap { UnlockPolicy(rawValue: $0) } ?? .selfUnlock
        let goalRequirementValue = goalRequirement.flatMap { GoalRequirement(rawValue: $0) } ?? .none
        
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
            lockPlanId: lockPlanUUID,
            lockPlanType: lockPlanTypeValue,
            lockMode: lockModeValue,
            unlockPolicy: unlockPolicyValue,
            goalRequirement: goalRequirementValue,
            quorumState: quorumState,
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
