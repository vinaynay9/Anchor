import Foundation

final class AuthDiagnostics {
    static let shared = AuthDiagnostics()

    private enum Keys {
        static let lastAuthError = "lastAuthError"
        static let lastAuthErrorContext = "lastAuthErrorContext"
    }

    private let defaults = UserDefaults.standard

    private init() {}

    func record(error: Error, context: String) {
        let nsError = error as NSError
        let message = "[\(nsError.domain)] \(nsError.code) \(nsError.userInfo)"
        defaults.set(message, forKey: Keys.lastAuthError)
        defaults.set(context, forKey: Keys.lastAuthErrorContext)
        print("⚠️ [AuthDiagnostics] \(context): \(message)")
    }

    func clear() {
        defaults.removeObject(forKey: Keys.lastAuthError)
        defaults.removeObject(forKey: Keys.lastAuthErrorContext)
    }

    var lastError: String? {
        defaults.string(forKey: Keys.lastAuthError)
    }

    var lastContext: String? {
        defaults.string(forKey: Keys.lastAuthErrorContext)
    }

    var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "unknown"
    }

    var googleClientID: String {
        Secrets.googleClientID
    }

    var googleClientIDMasked: String {
        mask(Secrets.googleClientID)
    }

    var googleReverseClientID: String {
        Secrets.googleReverseClientID
    }

    var googleReverseClientIDMasked: String {
        mask(Secrets.googleReverseClientID)
    }

    var urlSchemes: [String] {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return []
        }
        let schemes = urlTypes.compactMap { $0["CFBundleURLSchemes"] as? [String] }.flatMap { $0 }
        return schemes
    }

    var hasGoogleCallbackScheme: Bool {
        guard !googleReverseClientID.isEmpty else { return false }
        return urlSchemes.contains(googleReverseClientID)
    }

    var canConstructGoogleCallbackURL: Bool {
        guard !googleReverseClientID.isEmpty else { return false }
        return URL(string: "\(googleReverseClientID)://") != nil
    }

    private func mask(_ value: String) -> String {
        guard !value.isEmpty else { return "—" }
        if value.count <= 8 { return String(repeating: "•", count: value.count) }
        let prefix = value.prefix(4)
        let suffix = value.suffix(4)
        return "\(prefix)…\(suffix)"
    }
}
