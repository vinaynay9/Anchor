import Foundation
import FamilyControls
import Shared

final class V0AppBucketingService {
    static let shared = V0AppBucketingService()

    private let storage = AppGroupStorage.shared

    // Best-effort fallback; not exhaustive.
    private let bucketRules: [(bucket: V0AppBucket, substrings: [String])] = [
        (.social, ["tiktok", "musical.ly", "instagram", "snap", "snapchat", "facebook", "fb", "messenger", "twitter", "x.com", "reddit", "pinterest", "tumblr", "bereal"]),
        (.games, ["roblox", "minecraft", "fortnite", "epic", "riotgames", "leagueoflegends", "supercell", "clashofclans", "brawlstars", "pokemon", "monopoly", "amongus", "candycrush", "king", "callofduty", "steam"]),
        (.productivity, ["notion", "todoist", "ticktick", "things", "omnifocus", "asana", "trello", "jira", "monday", "clickup", "googledrive", "drive", "microsoft.office", "word", "excel", "powerpoint", "onenote", "evernote", "calendar"]),
        (.foodDelivery, ["ubereats", "uber.eats", "doordash", "grubhub", "postmates", "instacart", "gopuff"]),
        (.entertainmentStreaming, ["youtube", "netflix", "hulu", "disney", "primevideo", "amazon.video", "hbomax", "max", "peacock", "paramount", "spotify", "applemusic", "pandora", "soundcloud", "twitch", "crunchyroll", "plex"]),
        (.shopping, ["amazon", "walmart", "target", "costco", "ebay", "etsy", "shein", "temu", "aliexpress", "bestbuy", "homedepot", "lowes", "wayfair", "shop", "shopify"]),
        (.communication, ["imessage", "messages", "whatsapp", "telegram", "signal", "wechat", "line", "kik", "discord", "slack", "teams", "zoom", "meet", "gmail", "outlook"]),
        (.finance, ["chase", "bankofamerica", "bofa", "wellsfargo", "citi", "capitalone", "amex", "americanexpress", "venmo", "paypal", "cashapp", "zelle", "robinhood", "coinbase", "kraken", "binance", "fidelity", "schwab", "vanguard", "etrade", "sofi", "mint", "nerdwallet"]),
        (.sports, ["espn", "yahoo.sports", "thescore", "bleacherreport", "foxsports", "cbs.sports", "nbcsports", "mlb", "nfl", "nba", "fantasy", "sleeper", "underdog", "prizepicks", "draftkings", "fanduel", "betmgm", "caesars", "betrivers", "barstool", "pinnacle", "stake", "kalshi", "polymarket"]),
        (.news, ["nytimes", "wsj", "washingtonpost", "cnn", "foxnews", "bbc", "reuters", "bloomberg", "apnews", "substack"]),
        (.education, ["duolingo", "khanacademy", "coursera", "udemy", "edx", "brilliant", "quizlet", "chegg", "photomath", "canvas", "blackboard", "google.classroom"]),
        (.healthFitness, ["strava", "nike.run", "nrc", "peloton", "fitbit", "myfitnesspal", "calm", "headspace", "whoop", "garmin", "apple.health", "sleepcycle"]),
        (.travel, ["uber", "lyft", "airbnb", "expedia", "booking", "hotels", "delta", "united", "americanairlines", "southwest", "kayak", "hopper", "google.maps", "waze"]),
        (.utilities, ["settings", "photos", "camera", "calculator", "clock", "notes", "reminders", "weather", "files", "vpn", "authenticator", "googleauth", "microsoftauth"])
    ]

    private init() {}

    func bucket(for bundleID: String) -> V0AppBucket {
        let lowercased = bundleID.lowercased()
        for rule in bucketRules {
            if rule.substrings.contains(where: { lowercased.contains($0) }) {
                return rule.bucket
            }
        }
        return .other
    }

    func bucket(for applicationToken: ApplicationToken, selection: V0AppSelection) -> V0AppBucket {
        guard let bundleID = bundleID(for: applicationToken, selection: selection) else {
            return .other
        }
        return bucket(for: bundleID)
    }

    func bucket(for categoryToken: ActivityCategoryToken) -> V0AppBucket? {
        // Apple categories are used when chosen; per-app category is not reliably queryable, so bundle-id heuristics are fallback.
        let description = String(describing: categoryToken).lowercased()
        if description.contains("social") { return .social }
        if description.contains("game") { return .games }
        if description.contains("product") { return .productivity }
        if description.contains("food") || description.contains("drink") { return .foodDelivery }
        if description.contains("entertain") || description.contains("music") || description.contains("video") { return .entertainmentStreaming }
        if description.contains("shop") { return .shopping }
        if description.contains("communic") || description.contains("message") { return .communication }
        if description.contains("finance") { return .finance }
        if description.contains("sport") { return .sports }
        if description.contains("news") { return .news }
        if description.contains("educat") { return .education }
        if description.contains("health") || description.contains("fitness") { return .healthFitness }
        if description.contains("travel") { return .travel }
        if description.contains("utilit") { return .utilities }
        return nil
    }

    func presetTokens(for targetBucket: V0AppBucket, selection: V0AppSelection) -> (categories: Set<ActivityCategoryToken>, applications: Set<ApplicationToken>) {
        let categoryTokens = storage.decodeCategoryTokens(selection.blockedCategories)
        let matchedCategories = Set(categoryTokens.filter { bucket(for: $0) == targetBucket })

        let appTokens = storage.decodeApplicationTokens(selection.blockedApplications)
        let matchedApps = Set(appTokens.filter { bucket(for: $0, selection: selection) == targetBucket })

        return (matchedCategories, matchedApps)
    }

    func bundleID(for token: ApplicationToken, selection: V0AppSelection) -> String? {
        guard let data = try? JSONEncoder().encode(token) else { return nil }
        let key = storage.base64Key(for: data)
        return selection.applicationTokenBundleIDs[key]
    }
}
