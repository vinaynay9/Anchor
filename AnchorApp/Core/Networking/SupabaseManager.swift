import Foundation
import Supabase

// MARK: - SupabaseManager
//
// Initializes the Supabase client from Info.plist values injected via Anchor.xcconfig.
// Setup steps (one-time, in Xcode):
//   1. File → Add Package Dependencies → https://github.com/supabase/supabase-swift (2.x)
//   2. Project → Info → Configurations → set Debug + Release for AnchorApp → Anchor.xcconfig
//
// Usage anywhere in the app:
//   SupabaseManager.shared.client

final class SupabaseManager {
    static let shared = SupabaseManager()

    /// Non-optional client. Will be a no-op stub URL if xcconfig not wired — logs warning.
    let client: SupabaseClient

    private init() {
        let urlString = SupabaseManager.readPlistValue(key: "SUPABASE_URL")
        let anonKey   = SupabaseManager.readPlistValue(key: "SUPABASE_ANON_KEY")

        // Validate — fall back to a safe placeholder URL so the app doesn't crash
        // if Anchor.xcconfig isn't wired in Xcode yet (xcconfig missing from build config).
        let resolvedURL: URL
        if !urlString.isEmpty,
           !urlString.hasPrefix("$("),   // unexpanded xcconfig variable
           let url = URL(string: urlString) {
            resolvedURL = url
        } else {
            print("⚠️ [SupabaseManager] SUPABASE_URL not configured. Check Anchor.xcconfig is set as the build configuration in Xcode. Auth will not work.")
            resolvedURL = URL(string: "https://placeholder.supabase.co")!
        }

        let resolvedKey: String
        if !anonKey.isEmpty, !anonKey.hasPrefix("$(") {
            resolvedKey = anonKey
        } else {
            print("⚠️ [SupabaseManager] SUPABASE_ANON_KEY not configured. Check Anchor.xcconfig is set as the build configuration in Xcode. Auth will not work.")
            resolvedKey = "placeholder-key"
        }

        client = SupabaseClient(supabaseURL: resolvedURL, supabaseKey: resolvedKey)
    }

    // MARK: - Helpers

    /// True only when real (non-placeholder) values are present.
    var isConfigured: Bool {
        let url = SupabaseManager.readPlistValue(key: "SUPABASE_URL")
        let key = SupabaseManager.readPlistValue(key: "SUPABASE_ANON_KEY")
        return !url.isEmpty && !url.hasPrefix("$(") && url != "YOUR_SUPABASE_URL"
            && !key.isEmpty && !key.hasPrefix("$(") && key != "YOUR_SUPABASE_ANON_KEY"
    }

    static func readPlistValue(key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}
