import Foundation
import Shared

final class RemoteConfigService {
    static let shared = RemoteConfigService()

    private let storage = AppGroupStorage.shared
    private let session: URLSession

    private static let networkSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        return URLSession(configuration: config)
    }()

    private init(session: URLSession = RemoteConfigService.networkSession) {
        self.session = session
    }

    var currentConfig: RemoteAppConfig? {
        storage.getRemoteAppConfig()
    }

    func refresh() async {
        guard let url = URL(string: Secrets.apiBaseURL + Secrets.remoteConfigPath) else {
            return
        }

        guard let token = try? KeychainService.shared.get(forKey: AppConfig.UserDefaultsKeys.accessToken) else {
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return
            }

            let config = try JSONDecoder().decode(RemoteAppConfig.self, from: data)
            storage.setRemoteAppConfig(config)
        } catch {
            // Fail silently and rely on cached config if available.
        }
    }
}

struct DailyMetricsProfile: Codable {
    let display_name: String
    let birth_month: Int
    let birth_day: Int
}

struct DailyMetricsPayload: Codable {
    let user_id: String
    let date: String
    let timezone: String
    let reset_time_minutes: Int
    let metrics: [String: Double]
    let profile: DailyMetricsProfile?
}

final class AnalyticsIngestService {
    static let shared = AnalyticsIngestService()
    private init() {}

    // Keep this service independent from RemoteConfigService’s private session.
    private static let networkSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        return URLSession(configuration: config)
    }()

    func sendDailyProfileIfConfigured() async {
        guard let url = AppConfig.analyticsIngestURL else { return }

        let apiKey = AppConfig.analyticsIngestApiKey
        guard !apiKey.isEmpty else { return }

        guard let profile = AppGroupStorage.shared.getProfile() else { return }

        let today = DateFormatters.dayFormatter.string(from: Date())

        let payload = DailyMetricsPayload(
            user_id: AppGroupStorage.shared.getOrCreateAnalyticsUserId(),
            date: today,
            timezone: profile.timezone,
            reset_time_minutes: 0,
            metrics: [
                "social_minutes": 0,
                "video_game_minutes": 0,
                "streaming_minutes": 0,
                "shopping_minutes": 0,
                "news_minutes": 0,
                "sports_minutes": 0,
                "goals_completed": 0,
                "shield_opens": 0,
                "session_count": 0,
                "session_total_minutes": 0
            ],
            profile: DailyMetricsProfile(
                display_name: profile.displayName,
                birth_month: profile.birthMonth,
                birth_day: profile.birthDay
            )
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-anchor-api-key")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            return
        }

        do {
            _ = try await Self.networkSession.data(for: request)
        } catch {
            // best-effort
        }
    }
}
