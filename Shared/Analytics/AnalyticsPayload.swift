import Foundation

public enum AnalyticsUserState: String, Codable {
    case anchored
    case free
}

public struct AnalyticsContext: Codable, Equatable {
    public let challengeId: UUID?
    public let pledgeId: UUID?
    public let crewId: UUID?
    public let anchorId: UUID?
    
    public init(
        challengeId: UUID? = nil,
        pledgeId: UUID? = nil,
        crewId: UUID? = nil,
        anchorId: UUID? = nil
    ) {
        self.challengeId = challengeId
        self.pledgeId = pledgeId
        self.crewId = crewId
        self.anchorId = anchorId
    }
}

public struct AnalyticsMetrics: Codable, Equatable {
    public let doubleValues: [String: Double]
    public let stringValues: [String: String]
    
    public init(doubleValues: [String: Double] = [:], stringValues: [String: String] = [:]) {
        self.doubleValues = doubleValues
        self.stringValues = stringValues
    }
}

public struct AnalyticsPayload: Codable, Equatable {
    public let timestamp: Date
    public let userState: AnalyticsUserState
    public let context: AnalyticsContext?
    public let metrics: AnalyticsMetrics?
    
    public init(
        timestamp: Date = Date(),
        userState: AnalyticsUserState,
        context: AnalyticsContext? = nil,
        metrics: AnalyticsMetrics? = nil
    ) {
        self.timestamp = timestamp
        self.userState = userState
        self.context = context
        self.metrics = metrics
    }
}

public enum AnalyticsBuildType: String, Codable {
    case debug
    case release
    
    public static var current: AnalyticsBuildType {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
}

public struct AnalyticsRecord: Codable, Identifiable, Equatable {
    public static let schemaVersion = 1
    
    public let id: UUID
    public let event: AnalyticsEvent
    public let payload: AnalyticsPayload
    public let schemaVersion: Int
    public let buildType: AnalyticsBuildType
    public let dayId: String
    
    public init(
        id: UUID = UUID(),
        event: AnalyticsEvent,
        payload: AnalyticsPayload,
        schemaVersion: Int = AnalyticsRecord.schemaVersion,
        buildType: AnalyticsBuildType = .current,
        dayId: String
    ) {
        self.id = id
        self.event = event
        self.payload = payload
        self.schemaVersion = schemaVersion
        self.buildType = buildType
        self.dayId = dayId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case event
        case payload
        case schemaVersion
        case buildType
        case dayId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        event = try container.decode(AnalyticsEvent.self, forKey: .event)
        payload = try container.decode(AnalyticsPayload.self, forKey: .payload)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? AnalyticsRecord.schemaVersion
        buildType = try container.decodeIfPresent(AnalyticsBuildType.self, forKey: .buildType) ?? .debug
        dayId = try container.decodeIfPresent(String.self, forKey: .dayId) ?? UUID().uuidString
    }
}
