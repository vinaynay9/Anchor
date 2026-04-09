import Foundation
import Shared

protocol InviteServiceProtocol {
    func currentInviteState() async -> InviteState
    func refreshInviteStatsIfNeeded(force: Bool) async
    func sharePayload() async -> (url: URL, message: String)
    func incrementInviteCountLocal()
}

final class InviteService: InviteServiceProtocol {
    static let shared = InviteService()

    private let apiClient = APIClient.shared
    private let storage = AppGroupStorage.shared
    private let refreshInterval: TimeInterval = 24 * 60 * 60

    private init() {}

    func currentInviteState() async -> InviteState {
        if let existing = storage.getInviteState() {
            return existing
        }

        let inviterId = resolveInviterId()
        let inviteCode = generateInviteCode()
        let inviteLink = buildInviteLink(inviteCode: inviteCode, inviterId: inviterId)

        let state = InviteState(
            inviterId: inviterId,
            inviteCode: inviteCode,
            inviteLink: inviteLink,
            inviteCount: 0,
            lastRefreshAt: nil
        )
        storage.setInviteState(state)
        return state
    }

    func refreshInviteStatsIfNeeded(force: Bool = false) async {
        let state = await currentInviteState()
        if !force, let last = state.lastRefreshAt, Date().timeIntervalSince(last) < refreshInterval {
            return
        }

        guard isAPIConfigured() else {
            return
        }

        struct InviteStatsResponse: Decodable {
            let inviteCount: Int
        }

        do {
            let response: InviteStatsResponse = try await apiClient.request(
                .inviteStats(inviterId: state.inviterId, inviteCode: state.inviteCode),
                responseType: InviteStatsResponse.self
            )

            let updated = InviteState(
                inviterId: state.inviterId,
                inviteCode: state.inviteCode,
                inviteLink: state.inviteLink,
                inviteCount: max(0, response.inviteCount),
                lastRefreshAt: Date()
            )
            storage.setInviteState(updated)
        } catch {
            // Best-effort refresh. Keep existing state if the request fails.
        }
    }

    func sharePayload() async -> (url: URL, message: String) {
        let state = await currentInviteState()
        let url = URL(string: state.inviteLink) ?? AppConfig.inviteBaseURL
        let message = "Join me on Anchor. Use my link: \(url.absoluteString)"
        return (url, message)
    }

    func incrementInviteCountLocal() {
        storage.incrementInviteCountLocal()
    }

    private func resolveInviterId() -> String {
        if let currentUserId = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.currentUserId),
           !currentUserId.isEmpty {
            return currentUserId
        }
        if let existing = storage.getInviteState()?.inviterId, !existing.isEmpty {
            return existing
        }
        return UUID().uuidString
    }

    private func generateInviteCode() -> String {
        let raw = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(raw.prefix(10))
    }

    private func buildInviteLink(inviteCode: String, inviterId: String) -> String {
        var components = URLComponents(url: AppConfig.inviteBaseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "code", value: inviteCode),
            URLQueryItem(name: "inviter", value: inviterId)
        ]
        return components?.url?.absoluteString ?? AppConfig.inviteBaseURL.absoluteString
    }

    private func isAPIConfigured() -> Bool {
        // Legacy check — API now goes through Supabase. Returns false until wired.
        return SupabaseManager.shared.isConfigured
    }
}
