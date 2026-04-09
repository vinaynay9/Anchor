import Foundation
import Shared

// MARK: - RemoteConfigService
// AWS remote config endpoint removed. Remote config will be fetched from
// Supabase once connected (see SupabaseManager + SUPABASE_SETUP.md).
// For now this service returns the locally cached config if present.

final class RemoteConfigService {
    static let shared = RemoteConfigService()

    private let storage = AppGroupStorage.shared

    private init() {}

    var currentConfig: RemoteAppConfig? {
        storage.getRemoteAppConfig()
    }

    /// No-op until Supabase remote config is wired.
    /// TODO: [Supabase] fetch from supabase.from("remote_config").select().single()
    func refresh() async {
        // Remote config will come from Supabase once connected.
        // Cached config (if any) continues to be used.
    }
}

// MARK: - AnalyticsIngestService
// AWS Lambda analytics ingest removed.
// Analytics sync now goes through AggregateService → Supabase (see AggregateService.syncAggregates).

final class AnalyticsIngestService {
    static let shared = AnalyticsIngestService()
    private init() {}

    /// No-op — analytics now flow through AggregateService → Supabase daily_aggregates table.
    /// See AggregateService.syncAggregates() for the real implementation.
    func sendDailyProfileIfConfigured() async {
        // TODO: [Supabase] replaced by AggregateService.syncAggregates()
    }
}
