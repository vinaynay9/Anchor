import Foundation

// MARK: - SupabaseManager
//
// Initializes the Supabase client from Info.plist values injected via .xcconfig.
// Before connecting:
//   1. Add the supabase-swift SPM package (see SUPABASE_SETUP.md)
//   2. Create Anchor.xcconfig with SUPABASE_URL and SUPABASE_ANON_KEY
//   3. Add SUPABASE_URL and SUPABASE_ANON_KEY entries to Info.plist
//   4. Set Build Configuration to use Anchor.xcconfig
//
// Usage anywhere in the app:
//   let client = SupabaseManager.shared.client   // Supabase.SupabaseClient
//
// Once supabase-swift is added via SPM, uncomment the import and client lines below.

// MARK: - Placeholder (pre-SPM)
// Comment everything below this line out and uncomment the real implementation
// once you have added the supabase-swift package in Xcode.

final class SupabaseManager {
    static let shared = SupabaseManager()

    // TODO: [Supabase] Uncomment after adding supabase-swift SPM package
    // let client: SupabaseClient

    private init() {
        let url  = SupabaseManager.readPlistValue(key: "SUPABASE_URL")
        let key  = SupabaseManager.readPlistValue(key: "SUPABASE_ANON_KEY")

        guard !url.isEmpty, url != "YOUR_SUPABASE_URL",
              !key.isEmpty, key != "YOUR_SUPABASE_ANON_KEY" else {
            // Not fatal in pre-Supabase builds — services fall back gracefully.
            print("⚠️ [SupabaseManager] SUPABASE_URL or SUPABASE_ANON_KEY not configured in Info.plist. See SUPABASE_SETUP.md.")
            return
        }

        // TODO: [Supabase] Uncomment after adding supabase-swift SPM package:
        // guard let supabaseURL = URL(string: url) else {
        //     fatalError("[SupabaseManager] SUPABASE_URL '\(url)' is not a valid URL.")
        // }
        // client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
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

// MARK: - Real Implementation (activate after SPM)
//
// import Supabase
//
// final class SupabaseManager {
//     static let shared = SupabaseManager()
//     let client: SupabaseClient
//
//     private init() {
//         let urlString = SupabaseManager.readPlistValue(key: "SUPABASE_URL")
//         let anonKey   = SupabaseManager.readPlistValue(key: "SUPABASE_ANON_KEY")
//
//         guard !urlString.isEmpty, urlString != "YOUR_SUPABASE_URL" else {
//             fatalError("[SupabaseManager] SUPABASE_URL not set. Add it to your .xcconfig and Info.plist. See SUPABASE_SETUP.md.")
//         }
//         guard !anonKey.isEmpty, anonKey != "YOUR_SUPABASE_ANON_KEY" else {
//             fatalError("[SupabaseManager] SUPABASE_ANON_KEY not set. Add it to your .xcconfig and Info.plist. See SUPABASE_SETUP.md.")
//         }
//         guard let url = URL(string: urlString) else {
//             fatalError("[SupabaseManager] '\(urlString)' is not a valid URL.")
//         }
//         client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
//     }
//
//     static func readPlistValue(key: String) -> String {
//         Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
//     }
// }
