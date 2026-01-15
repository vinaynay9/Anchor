import Foundation
import Shared

enum AnalyticsRange: String, CaseIterable {
    case last24Hours = "24H"
    case last7Days = "7D"
    case last30Days = "30D"
    case all = "All"
    
    var days: Int? {
        switch self {
        case .last24Hours: return nil
        case .last7Days: return 7
        case .last30Days: return 30
        case .all: return nil
        }
    }

    var hours: Int? {
        switch self {
        case .last24Hours: return 24
        default: return nil
        }
    }
}

struct AnalyticsTimeSeriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct AnalyticsHourPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let value: Double
}

enum AnalyticsTrendDirection: String {
    case up = "up"
    case down = "down"
    case flat = "flat"
}

struct AnalyticsTrend {
    let direction: AnalyticsTrendDirection
    let deltaPercent: Double?
}

struct ImpulseMetrics {
    let shieldHitsPerDay: [AnalyticsTimeSeriesPoint]
    let shieldHitsByHour: [AnalyticsHourPoint]
    let medianImpulseRecoverySeconds: Double?
    let medianShieldToAnchorSeconds: Double?
    let appOpensPerDay: [AnalyticsTimeSeriesPoint]
    let appOpensAnchored: Int
    let appOpensFree: Int
    let interactionPattern: String
    let trend: AnalyticsTrend
}

struct DisciplineMetrics {
    let pledgeCompletionsPerDay: [AnalyticsTimeSeriesPoint]
    let medianCompletionLatencySeconds: Double?
    let emergencyUnanchorsPerDay: [AnalyticsTimeSeriesPoint]
    let timeSinceLastEmergencyDays: Int?
}

struct SocialMetrics {
    let profileViewsPerDay: [AnalyticsTimeSeriesPoint]
    let proofSubmissionsPerDay: [AnalyticsTimeSeriesPoint]
}

struct ChallengesMetrics {
    let challengeCreatesPerDay: [AnalyticsTimeSeriesPoint]
    let challengeCompletionsPerDay: [AnalyticsTimeSeriesPoint]
    let challengeConcessionsPerDay: [AnalyticsTimeSeriesPoint]
}

struct NetworkMetrics {
    let invitesSentPerDay: [AnalyticsTimeSeriesPoint]
    let invitesAcceptedPerDay: [AnalyticsTimeSeriesPoint]
}

struct SilentSuccessMetrics {
    let lowInteractionDays: Int
    let zeroEmergencyUnanchors: Bool
    let longestNoInteractionStreakDays: Int
}

struct AnalyticsDashboardData {
    let summary: AnalyticsSummaryMetrics
    let impulse: ImpulseMetrics
    let discipline: DisciplineMetrics
    let social: SocialMetrics
    let challenges: ChallengesMetrics
    let network: NetworkMetrics
    let silentSuccess: SilentSuccessMetrics
    let latestEventAt: Date?
}

struct AnalyticsSummaryMetrics {
    let shieldHitsToday: Int
    let shieldHitsYesterday: Int
    let emergencyUnanchorsLast7Days: Int
    let medianPledgeCompletionSecondsLast7Days: Double?
    let medianPledgeCompletionTrend: AnalyticsTrend
}

final class AnalyticsInsightsService {
    static let shared = AnalyticsInsightsService()
    
    private let calendar = Calendar.current
    private let storage = AnalyticsStorage.shared
    
    private init() {}
    
    func buildDashboard(range: AnalyticsRange) -> AnalyticsDashboardData {
        let events = loadEvents(range: range)
        let allEvents = storage.loadAllRecords()
        let appOpens = events.filter { $0.event == .appOpened }
        let shieldHits = events.filter { $0.event == .shieldHit }
        let pledges = events.filter { $0.event == .pledgeCompleted }
        let emergency = events.filter { $0.event == .emergencyUnanchorUsed }
        let profiles = events.filter { $0.event == .profileViewed }
        let proofs = events.filter { $0.event == .proofSubmitted }
        let challenges = events.filter { $0.event == .challengeCreated }
        let challengeCompletions = events.filter { $0.event == .challengeCompleted }
        let challengeConcessions = events.filter { $0.event == .challengeConceded }
        let invitesSent = events.filter { $0.event == .inviteSent }
        let invitesAccepted = events.filter { $0.event == .inviteAccepted }
        
        let impulse = ImpulseMetrics(
            shieldHitsPerDay: timeSeriesCounts(shieldHits),
            shieldHitsByHour: hourCounts(shieldHits),
            medianImpulseRecoverySeconds: medianMetric(shieldHits, key: "impulseRecoverySeconds"),
            medianShieldToAnchorSeconds: medianMetric(appOpens, key: "timeFromShieldHitSeconds"),
            appOpensPerDay: timeSeriesCounts(appOpens),
            appOpensAnchored: appOpens.filter { $0.payload.userState == .anchored }.count,
            appOpensFree: appOpens.filter { $0.payload.userState == .free }.count,
            interactionPattern: interactionPattern(from: appOpens + shieldHits),
            trend: trendForEventCount(event: .shieldHit, range: range)
        )
        
        let discipline = DisciplineMetrics(
            pledgeCompletionsPerDay: timeSeriesCounts(pledges),
            medianCompletionLatencySeconds: medianMetric(pledges, key: "completionLatencySeconds"),
            emergencyUnanchorsPerDay: timeSeriesCounts(emergency),
            timeSinceLastEmergencyDays: timeSinceLastEventDays(emergency)
        )
        
        let social = SocialMetrics(
            profileViewsPerDay: timeSeriesCounts(profiles),
            proofSubmissionsPerDay: timeSeriesCounts(proofs)
        )
        
        let challengesMetrics = ChallengesMetrics(
            challengeCreatesPerDay: timeSeriesCounts(challenges),
            challengeCompletionsPerDay: timeSeriesCounts(challengeCompletions),
            challengeConcessionsPerDay: timeSeriesCounts(challengeConcessions)
        )
        
        let network = NetworkMetrics(
            invitesSentPerDay: timeSeriesCounts(invitesSent),
            invitesAcceptedPerDay: timeSeriesCounts(invitesAccepted)
        )
        
        let silentSuccess = SilentSuccessMetrics(
            lowInteractionDays: lowInteractionDays(events: events),
            zeroEmergencyUnanchors: emergency.isEmpty,
            longestNoInteractionStreakDays: longestNoInteractionStreak(events: events)
        )

        let summary = AnalyticsSummaryMetrics(
            shieldHitsToday: countForDay(event: .shieldHit, offsetDays: 0, events: allEvents),
            shieldHitsYesterday: countForDay(event: .shieldHit, offsetDays: 1, events: allEvents),
            emergencyUnanchorsLast7Days: countForRange(event: .emergencyUnanchorUsed, days: 7, events: allEvents),
            medianPledgeCompletionSecondsLast7Days: medianMetric(
                loadEvents(range: .last7Days).filter { $0.event == .pledgeCompleted },
                key: "completionLatencySeconds"
            ),
            medianPledgeCompletionTrend: trendForMedian(
                event: .pledgeCompleted,
                metricKey: "completionLatencySeconds"
            )
        )
        
        let latestEventAt = allEvents.map(\.payload.timestamp).max()
        
        return AnalyticsDashboardData(
            summary: summary,
            impulse: impulse,
            discipline: discipline,
            social: social,
            challenges: challengesMetrics,
            network: network,
            silentSuccess: silentSuccess,
            latestEventAt: latestEventAt
        )
    }
    
    private func loadEvents(range: AnalyticsRange) -> [AnalyticsRecord] {
        let allEvents = storage.loadAllRecords()
        if let hours = range.hours {
            let start = Date().addingTimeInterval(TimeInterval(-hours * 3600))
            return allEvents.filter { $0.payload.timestamp >= start }
        }
        guard let days = range.days else { return allEvents }
        guard let start = calendar.date(byAdding: .day, value: -days + 1, to: Date()) else {
            return allEvents
        }
        return allEvents.filter { $0.payload.timestamp >= start }
    }
    
    private func timeSeriesCounts(_ events: [AnalyticsRecord]) -> [AnalyticsTimeSeriesPoint] {
        guard !events.isEmpty else { return [] }
        let grouped = Dictionary(grouping: events) { calendar.startOfDay(for: $0.payload.timestamp) }
        return grouped
            .map { AnalyticsTimeSeriesPoint(date: $0.key, value: Double($0.value.count)) }
            .sorted { $0.date < $1.date }
    }
    
    private func hourCounts(_ events: [AnalyticsRecord]) -> [AnalyticsHourPoint] {
        var counts: [Int: Int] = [:]
        for event in events {
            let hour = calendar.component(.hour, from: event.payload.timestamp)
            counts[hour, default: 0] += 1
        }
        return (0..<24).map { hour in
            AnalyticsHourPoint(hour: hour, value: Double(counts[hour] ?? 0))
        }
    }
    
    private func medianMetric(_ events: [AnalyticsRecord], key: String) -> Double? {
        let values = events.compactMap { $0.payload.metrics?.doubleValues[key] }.sorted()
        guard !values.isEmpty else { return nil }
        let mid = values.count / 2
        if values.count % 2 == 0 {
            return (values[mid - 1] + values[mid]) / 2
        }
        return values[mid]
    }
    
    private func interactionPattern(from events: [AnalyticsRecord]) -> String {
        let timestamps = events.map { $0.payload.timestamp }.sorted()
        guard timestamps.count > 2 else { return "Insufficient data" }
        let intervals = zip(timestamps.dropFirst(), timestamps).map { $0.timeIntervalSince($1) }
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.reduce(0) { $0 + pow($1 - mean, 2) } / Double(intervals.count)
        let stdDev = sqrt(variance)
        let coefficient = mean > 0 ? stdDev / mean : 0
        return coefficient > 1.0 ? "Bursty" : "Steady"
    }
    
    private func trendForEventCount(event: AnalyticsEvent, range: AnalyticsRange) -> AnalyticsTrend {
        guard let days = range.days else {
            return AnalyticsTrend(direction: .flat, deltaPercent: nil)
        }
        let current = loadEvents(range: range).filter { $0.event == event }.count
        guard let start = calendar.date(byAdding: .day, value: -days * 2 + 1, to: Date()) else {
            return AnalyticsTrend(direction: .flat, deltaPercent: nil)
        }
        let previousRangeEnd = calendar.date(byAdding: .day, value: -days + 1, to: Date()) ?? Date()
        let previous = storage.loadAllRecords().filter {
            $0.event == event && $0.payload.timestamp >= start && $0.payload.timestamp < previousRangeEnd
        }.count
        
        guard previous > 0 else {
            return AnalyticsTrend(direction: current > 0 ? .up : .flat, deltaPercent: nil)
        }
        let delta = Double(current - previous) / Double(previous)
        let direction: AnalyticsTrendDirection
        if abs(delta) < 0.05 {
            direction = .flat
        } else {
            direction = delta > 0 ? .up : .down
        }
        return AnalyticsTrend(direction: direction, deltaPercent: delta)
    }
    
    private func timeSinceLastEventDays(_ events: [AnalyticsRecord]) -> Int? {
        guard let last = events.map(\.payload.timestamp).max() else { return nil }
        let days = calendar.dateComponents([.day], from: last, to: Date()).day ?? 0
        return max(days, 0)
    }

    private func countForDay(event: AnalyticsEvent, offsetDays: Int, events: [AnalyticsRecord]) -> Int {
        guard let day = calendar.date(byAdding: .day, value: -offsetDays, to: Date()) else { return 0 }
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return events.filter { $0.event == event && $0.payload.timestamp >= start && $0.payload.timestamp < end }.count
    }

    private func countForRange(event: AnalyticsEvent, days: Int, events: [AnalyticsRecord]) -> Int {
        guard let start = calendar.date(byAdding: .day, value: -days + 1, to: Date()) else { return 0 }
        return events.filter { $0.event == event && $0.payload.timestamp >= start }.count
    }

    private func trendForMedian(event: AnalyticsEvent, metricKey: String) -> AnalyticsTrend {
        let currentValues = loadEvents(range: .last7Days)
            .filter { $0.event == event }
        let currentMedian = medianMetric(currentValues, key: metricKey)
        
        guard let start = calendar.date(byAdding: .day, value: -14 + 1, to: Date()),
              let previousEnd = calendar.date(byAdding: .day, value: -7 + 1, to: Date()) else {
            return AnalyticsTrend(direction: .flat, deltaPercent: nil)
        }
        let previousValues = storage.loadAllRecords().filter {
            $0.event == event && $0.payload.timestamp >= start && $0.payload.timestamp < previousEnd
        }
        let previousMedian = medianMetric(previousValues, key: metricKey)
        guard let currentMedian, let previousMedian, previousMedian > 0 else {
            return AnalyticsTrend(direction: .flat, deltaPercent: nil)
        }
        let delta = (currentMedian - previousMedian) / previousMedian
        let direction: AnalyticsTrendDirection
        if abs(delta) < 0.05 {
            direction = .flat
        } else {
            direction = delta > 0 ? .up : .down
        }
        return AnalyticsTrend(direction: direction, deltaPercent: delta)
    }
    
    private func lowInteractionDays(events: [AnalyticsRecord]) -> Int {
        let appOpens = events.filter { $0.event == .appOpened }
        let shieldHits = events.filter { $0.event == .shieldHit }
        let appByDay = Dictionary(grouping: appOpens) { calendar.startOfDay(for: $0.payload.timestamp) }
        let shieldByDay = Dictionary(grouping: shieldHits) { calendar.startOfDay(for: $0.payload.timestamp) }
        let days = Set(appByDay.keys).union(shieldByDay.keys)
        return days.filter { (appByDay[$0]?.count ?? 0) <= 1 && (shieldByDay[$0]?.count ?? 0) == 0 }.count
    }
    
    private func longestNoInteractionStreak(events: [AnalyticsRecord]) -> Int {
        let relevant = events.filter { $0.event == .appOpened || $0.event == .shieldHit }
        let days = Set(relevant.map { calendar.startOfDay(for: $0.payload.timestamp) })
        guard let earliest = days.min(), let latest = days.max() else { return 0 }
        var current = 0
        var longest = 0
        var day = calendar.startOfDay(for: earliest)
        while day <= latest {
            if days.contains(day) {
                current = 0
            } else {
                current += 1
                longest = max(longest, current)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return longest
    }
}
