import Foundation
import CryptoKit

public enum AnalyticsUtilities {
    public static func hashToken(_ value: String?, salt: String) -> String? {
        guard let value, !value.isEmpty, !salt.isEmpty else { return nil }
        let combined = salt + ":" + value
        let digest = SHA256.hash(data: Data(combined.utf8))
        let hash = digest.compactMap { String(format: "%02x", $0) }.joined()
        return String(hash.prefix(12)).lowercased()
    }
}
