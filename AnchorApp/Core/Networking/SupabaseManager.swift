import Foundation
import Supabase

// MARK: - SupabaseManager
//
// Initializes the Supabase client from Info.plist values injected via Anchor.xcconfig.
// Setup steps:
//   1. Add the supabase-swift SPM package (File → Add Package Dependencies)
//   2. Xcode → Project → Info → Configurations: set Debug + Release to AnchorApp/Anchor.xcconfig
//
// Usage anywhere in the app:
//   let client = SupabaseManager.shared.client

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let urlString = SupabaseManager.readPlistValue(key: "SUPABASE_URL")
        let anonKey   = SupabaseManager.readPlistValue(key: "SUPABASE_ANON_KEY")

        guard !urlString.isEmpty, urlString != "YOUR_SUPABASE_URL",
              let url = URL(string: urlString) else {
            fatalError("[SupabaseManager] SUPABASE_URL not set or invalid. Check Anchor.xcconfig and Info.plist. See SUPABASE_SETUP.md.")
        }
        guard !anonKey.isEmpty, anonKey != "YOUR_SUPABASE_ANON_KEY" else {
            fatalError("[SupabaseManager] SUPABASE_ANON_KEY not set. Check Anchor.xcconfig and Info.plist. See SUPABASE_SETUP.md.")
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    // MARK: - Helpers

    var isConfigured: Bool {
        let url = SupabaseManager.readPlistValue(key: "SUPABASE_URL")
        let key = SupabaseManager.readPlistValue(key: "SUPABASE_ANON_KEY")
        return !url.isEmpty && url != "YOUR_SUPABASE_URL"
            && !key.isEmpty && key != "YOUR_SUPABASE_ANON_KEY"
    }

    static func readPlistValue(key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}
