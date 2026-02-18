import Foundation
import Combine

// MARK: - Notification Names
extension Notification.Name {
    public static let appGroupDidUpdate = Notification.Name("appGroupDidUpdate")
}

// MARK: - App Group Storage Keys
public enum AppGroupStorageKey: String {
    case v0Goals = "v0_goals"
    case v0UnlockConfig = "v0_unlockConfig"
    case v0AppSelection = "v0_appSelection"
    case v0DailyState = "v0_dailyState"
    case v0IsLocked = "v0_isLocked"
}

public final class AppGroupStorage {
    public static let shared = AppGroupStorage()

    private let defaults: UserDefaults?
    public static let appGroupIdentifier = "group.com.anchor.app"

    public let updatesPublisher: AnyPublisher<String?, Never>

    private init() {
        defaults = UserDefaults(suiteName: Self.appGroupIdentifier)
        updatesPublisher = NotificationCenter.default
            .publisher(for: .appGroupDidUpdate)
            .map { $0.object as? String }
            .eraseToAnyPublisher()
    }

    public func appGroupContainerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier)
    }

    private func notifyUpdate(forKey key: AppGroupStorageKey) {
        NotificationCenter.default.post(name: .appGroupDidUpdate, object: key.rawValue)
    }

    // MARK: - V0 Goals
    public func getV0Goals() -> [V0Goal] {
        guard let data = defaults?.data(forKey: AppGroupStorageKey.v0Goals.rawValue),
              let goals = try? JSONDecoder().decode([V0Goal].self, from: data) else {
            return []
        }
        return goals
    }

    public func setV0Goals(_ goals: [V0Goal]) {
        guard let defaults = defaults else { return }
        let data = try? JSONEncoder().encode(goals)
        defaults.set(data, forKey: AppGroupStorageKey.v0Goals.rawValue)
        notifyUpdate(forKey: .v0Goals)
    }

    // MARK: - V0 Unlock Config
    public func getV0UnlockConfig() -> V0UnlockConfig? {
        guard let data = defaults?.data(forKey: AppGroupStorageKey.v0UnlockConfig.rawValue) else { return nil }
        return try? JSONDecoder().decode(V0UnlockConfig.self, from: data)
    }

    public func setV0UnlockConfig(_ config: V0UnlockConfig?) {
        guard let defaults = defaults else { return }
        if let config = config {
            let data = try? JSONEncoder().encode(config)
            defaults.set(data, forKey: AppGroupStorageKey.v0UnlockConfig.rawValue)
        } else {
            defaults.removeObject(forKey: AppGroupStorageKey.v0UnlockConfig.rawValue)
        }
        notifyUpdate(forKey: .v0UnlockConfig)
    }

    // MARK: - V0 App Selection
    public func getV0AppSelection() -> V0AppSelection {
        guard let data = defaults?.data(forKey: AppGroupStorageKey.v0AppSelection.rawValue),
              let selection = try? JSONDecoder().decode(V0AppSelection.self, from: data) else {
            return V0AppSelection()
        }
        return selection
    }

    public func setV0AppSelection(_ selection: V0AppSelection) {
        guard let defaults = defaults else { return }
        let data = try? JSONEncoder().encode(selection)
        defaults.set(data, forKey: AppGroupStorageKey.v0AppSelection.rawValue)
        notifyUpdate(forKey: .v0AppSelection)
    }

    // MARK: - V0 Daily State
    public func getV0DailyState() -> V0DailyState {
        guard let data = defaults?.data(forKey: AppGroupStorageKey.v0DailyState.rawValue),
              let state = try? JSONDecoder().decode(V0DailyState.self, from: data) else {
            return V0DailyState()
        }
        return state
    }

    public func setV0DailyState(_ state: V0DailyState) {
        guard let defaults = defaults else { return }
        let data = try? JSONEncoder().encode(state)
        defaults.set(data, forKey: AppGroupStorageKey.v0DailyState.rawValue)
        notifyUpdate(forKey: .v0DailyState)
    }

    // MARK: - V0 Lock State
    public func getV0IsLocked() -> Bool {
        defaults?.bool(forKey: AppGroupStorageKey.v0IsLocked.rawValue) ?? true
    }

    public func setV0IsLocked(_ isLocked: Bool) {
        defaults?.set(isLocked, forKey: AppGroupStorageKey.v0IsLocked.rawValue)
        notifyUpdate(forKey: .v0IsLocked)
    }

    public func base64Key(for tokenData: Data) -> String {
        tokenData.base64EncodedString()
    }
}
